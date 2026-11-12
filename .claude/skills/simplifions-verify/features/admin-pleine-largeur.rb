require_relative '../harness'

DOSSIER = 'admin-pleine-largeur'.freeze
LARGEUR_DU_SITE = 1248

LARGEURS = <<~JS.freeze
  (() => {
    const largeur = (e) => e && Math.round(e.getBoundingClientRect().width);
    const contenu = Array.from(document.querySelectorAll('main [class~=fr-container]')).filter(e => !e.closest('.fr-notice, dialog')).pop();
    return { fenetre: document.documentElement.clientWidth, entete: largeur(document.querySelector('.fr-header__body > div')),
             contenu: largeur(contenu), pied: largeur(document.querySelector('.fr-footer > [class~=fr-container]')) };
  })()
JS

def largeurs(page, chemin, fenetre)
  page.current_window.resize_to(fenetre, 1000)
  page.visit(chemin)
  page.evaluate_script(LARGEURS).tap { Verify.evidence(DOSSIER, page, "#{chemin.parameterize}-#{fenetre}", it.to_json) }
end

def a_la_largeur(page, chemins, fenetre, attendue)
  chemins.each do |chemin|
    mesure = largeurs(page, chemin, fenetre)
    cible = attendue || mesure['fenetre']
    raise "#{chemin} à #{fenetre} px : #{mesure}" unless mesure.values_at('entete', 'contenu', 'pied').all?(cible)
  end
end

def panneau_collant(page, solution)
  page.current_window.resize_to(1440, 900)
  page.visit("/admin/solutions/#{solution.id}/edit")
  haut = page.evaluate_script("(() => { window.scrollTo(0, 900); return Math.round(document.querySelector(\"aside[aria-labelledby='etat-et-actions']\").getBoundingClientRect().top) })()")
  Verify.evidence(DOSSIER, page, 'panneau-apres-defilement', "haut_du_panneau=#{haut}")
  raise "panneau à #{haut} px du haut après défilement" unless haut == 16
end

Verify.drive(__FILE__) do |page|
  solution = Solution.left_joins(:integrations_qu_elle_expose).group(:id).order(Arel.sql('count(integrations.id) desc')).first
  admin = ['/admin', '/admin/organisations', "/admin/solutions/#{solution.id}/edit"]
  Verify.check('Public width') { a_la_largeur(page, ['/'], 1440, LARGEUR_DU_SITE) }
  Verify.login(page)
  Verify.check('Admin width') { a_la_largeur(page, admin, 1440, nil) }
  Verify.check('Admin at 1024 px') { a_la_largeur(page, admin, 1024, largeurs(page, '/', 1024)['contenu']) }
  Verify.check('Preview') do
    contenu = largeurs(page, "/admin/solutions/#{solution.id}/previsualisation", 1440)['contenu']
    raise "contenu prévisualisé #{contenu} px" unless contenu == LARGEUR_DU_SITE
  end
  Verify.check('Sticky panel') { panneau_collant(page, solution) }
  Verify.check('Proof') { Verify.logout(page) }
end
