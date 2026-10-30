require_relative '../harness'

DOSSIER = 'onglet-solutions-integratrices'.freeze
TITRES_QUI_DEBORDENT = <<~JS.freeze
  [...document.querySelectorAll('#solutions-integratrices h3 > button')].some(b => b.getBoundingClientRect().right > document.documentElement.clientWidth)
JS

def titre_de_categorie_attendu(categorie, solutions)
  badges = [I18n.t("public.moyens_acces.#{categorie}.nombre", count: solutions.size)]
  badges << 'Sans développement' unless categorie == :brique_logicielle
  [I18n.t("public.solutions_integratrices.#{categorie}.titre").squish, badges, I18n.t("public.solutions_integratrices.#{categorie}.description")]
end

def titre_de_categorie_lu(panneau, bouton)
  [bouton.find('.section-depliable__titre').text.squish, bouton.all('.fr-badge').map { it.text(:all).squish },
   panneau.find("##{bouton['aria-controls']} > p:first-child").text(:all).squish]
end

def titres_sans_debord(page, panneau, lus)
  [1280, 375].each do |largeur|
    page.current_window.resize_to(largeur, 1024)
    page.scroll_to(panneau, align: :top)
    raise "titre qui déborde à #{largeur} px" if page.evaluate_script(TITRES_QUI_DEBORDENT)

    Verify.evidence(DOSSIER, page, "titres-#{largeur}", "largeur=#{largeur} deborde=false titres=#{lus.inspect}")
  end
  page.current_window.resize_to(1280, 1024)
end

def titres_de_categorie(page, panneau, par_categorie)
  lus = panneau.all('h3 > .section-depliable__bouton').map { titre_de_categorie_lu(panneau, it) }
  attendus = par_categorie.map { |categorie, solutions| titre_de_categorie_attendu(categorie, solutions) }
  raise "titres #{lus.inspect} != #{attendus.inspect}" unless lus == attendus

  titres_sans_debord(page, panneau, lus)
end

def ouvrir_l_onglet(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  onglet = page.find('[role=tab][aria-controls=solutions-integratrices]')
  onglet.click
  panneau = page.find('#solutions-integratrices.fr-tabs__panel--selected')
  page.assert_selector('#donnees-disponibles', visible: :hidden)
  [onglet, panneau]
end

def mise_en_page_du_panneau(page, panneau)
  "categories=#{panneau.all('h3 > .section-depliable__bouton').map(&:text).join(' | ')} " \
    "fond=#{page.evaluate_script("getComputedStyle(document.getElementById('solutions-integratrices')).backgroundColor")} " \
    "largeur_panneau=#{panneau.rect.width.round} largeur_fenetre=#{page.evaluate_script('document.documentElement.clientWidth')}"
end

def cartes_dans_l_ordre(onglet, panneau, par_categorie)
  attendu = par_categorie.values.sum(&:size)
  raise "onglet #{onglet.text.inspect}" unless onglet.text == "Solutions ayant intégré ces données (#{attendu})"

  noms = panneau.all('.solution-integratrice-card__title').map(&:text)
  raise "cartes #{noms.size} != base #{attendu}" unless noms == par_categorie.values.flatten.map(&:nom)

  [attendu, noms]
end

def prouver_l_onglet(page, onglet, panneau, par_categorie)
  attendu, noms = cartes_dans_l_ordre(onglet, panneau, par_categorie)
  page.scroll_to(panneau, align: :top)
  Verify.evidence(DOSSIER, page, 'onglet-ouvert',
    "onglet=#{onglet.text.inspect} cartes=#{noms.size} base=#{attendu} premiere=#{noms.first.inspect} #{mise_en_page_du_panneau(page, panneau)}")
end

def replier_la_categorie(page, categorie)
  categorie.click
  page.assert_selector("##{categorie['aria-controls']}", visible: :hidden)
  Verify.evidence(DOSSIER, page, 'categorie-fermee', "titre=#{categorie.text.inspect} aria_expanded=#{categorie['aria-expanded']}")
  categorie['aria-expanded']
end

def categorie_repliee_puis_rouverte(page, panneau)
  categorie = panneau.first('.section-depliable__bouton')
  fermee = replier_la_categorie(page, categorie)
  categorie.send_keys(:enter)
  focus = page.evaluate_script('document.activeElement.className')
  page.assert_selector("##{categorie['aria-controls']} .solution-integratrice-card")
  Verify.evidence(DOSSIER, page, 'categorie',
    "titre=#{categorie.text.inspect} apres_clic=#{fermee} focus_apres_entree=#{focus.inspect} apres_entree=#{categorie['aria-expanded']}")
end

def total_de_la_modale(modale) = modale.text.squish[%r{Sur l’ensemble du cas d’usage : (\d+/\d+)}, 1]

def comparer_carte_et_modale(page, carte, modale)
  total = total_de_la_modale(modale)
  raise "carte #{carte} != modale #{total}" unless carte == total

  Verify.evidence(DOSSIER, page, 'modale', "solution=#{modale.find('h2').text.inspect} carte=#{carte} modale=#{total}")
end

def oeil_de_la_premiere_carte(page, panneau)
  oeil = panneau.first('.solution-integratrice-card button.fr-icon-eye-line')
  carte = oeil.ancestor('.solution-integratrice-card').find('.integration-indicator__count').text
  oeil.click
  comparer_carte_et_modale(page, carte, page.find("dialog##{oeil['aria-controls']}[open]"))
  page.send_keys(:escape)
  page.assert_no_selector("dialog##{oeil['aria-controls']}[open]")
end

def haut(page, selecteur) = page.evaluate_script("document.querySelector('#{selecteur}').getBoundingClientRect().top").round
def hauts(page) = "haut_des_onglets=#{haut(page, '.fr-tabs')} haut_du_panneau=#{haut(page, '#solutions-integratrices')}"

def arrivee_sur_l_onglet_solutions(page, etape, suite = '')
  page.assert_selector('#solutions-integratrices.fr-tabs__panel--selected', wait: 20)
  sleep 0.5
  Verify.evidence(DOSSIER, page, etape, "url=#{page.current_url} #{suite}#{hauts(page)}")
end

def ancre_depuis_un_autre_site_puis_par_turbo(page, demarche)
  page.visit("/demarches/#{demarche.slug}#solutions-integratrices")
  arrivee_sur_l_onglet_solutions(page, 'lien-externe')
  page.visit('/demarches')
  page.execute_script("Turbo.visit('/demarches/#{demarche.slug}#solutions-integratrices')")
  arrivee_sur_l_onglet_solutions(page, 'lien-interne')
end

def ancre_depuis_le_sommaire(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  page.assert_selector('#donnees-disponibles.fr-tabs__panel--selected')
  page.execute_script('window.memeDocument = true')
  page.find('nav.fr-summary').click_link('Solutions ayant intégré ces données')
  page.assert_selector('#solutions-integratrices.fr-tabs__panel--selected', wait: 20)
  raise 'le sommaire a rechargé la page' unless page.evaluate_script('window.memeDocument')

  arrivee_sur_l_onglet_solutions(page, 'sommaire', 'sans_rechargement=true ')
end

def bas(rect) = rect.y + rect.height
def cartes_visibles(solutions) = solutions.all('.solution-integratrice-card').size

def sans_js(demarche)
  page = Verify.session(javascript: false)
  page.visit("/demarches/#{demarche.slug}")
  donnees = bas(page.find('#donnees-disponibles').rect)
  solutions = page.find('#solutions-integratrices')
  debut = solutions.rect.y
  raise "solutions à #{debut}, données jusqu'à #{donnees}" unless debut >= donnees

  page.scroll_to(solutions, align: :top)
  Verify.evidence(DOSSIER, page, 'sans-js', "donnees_bas=#{donnees.round} solutions_haut=#{debut.round} cartes_visibles=#{cartes_visibles(solutions)}")
ensure
  page&.quit
end

Verify.drive(__FILE__) do |page|
  demarche = Demarche.visibles.order(:id).find { it.integratrices_par_categorie.any? }
  par_categorie = demarche.integratrices_par_categorie
  onglet, panneau = Verify.check('Open') { ouvrir_l_onglet(page, demarche) }
  Verify.check('Proof') { prouver_l_onglet(page, onglet, panneau, par_categorie) }
  Verify.check('Titles') { titres_de_categorie(page, panneau, par_categorie) }
  Verify.check('Category') { categorie_repliee_puis_rouverte(page, panneau) }
  Verify.check('Eye') { oeil_de_la_premiere_carte(page, panneau) }
  Verify.check('Anchor') do
    ancre_depuis_un_autre_site_puis_par_turbo(page, demarche)
    ancre_depuis_le_sommaire(page, demarche)
  end
  Verify.check('No JS') do
    page.quit
    sans_js(demarche)
  end
end
