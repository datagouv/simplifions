require_relative '../harness'

DOSSIER = 'affichage-personnalise'.freeze

FILTRES = %w[api logiciels sites].freeze
TAG_LOGICIELS = 'Logiciels métiers « clé en main »'.freeze
TAG_SITES = 'Sites de consultation des données'.freeze
TAG_API = 'API et jeux de données'.freeze

VOLET = '.fr-collapse, [data-section-depliable-target=contenu]'.freeze
VOLET_DEPLIE = '.fr-collapse.fr-collapse--expanded, [data-section-depliable-target=contenu]:not([hidden])'.freeze

def compter_volets(page, panneau, filtre, volet) = page.evaluate_script("document.querySelectorAll('##{panneau} [data-filtre=#{filtre}] > :is(#{volet})').length")

def sections_depliees(page, panneau) = FILTRES.index_with { compter_volets(page, panneau, it, VOLET_DEPLIE) }

def sections(page, panneau) = FILTRES.index_with { compter_volets(page, panneau, it, VOLET) }

def sections_masquees(page)
  page.evaluate_script("[...document.querySelectorAll('[data-filtre]')].filter((bloc) => getComputedStyle(bloc).display === 'none').length")
end

def tag(page, libelle) = page.find('button.fr-tag', text: libelle)

def basculer_au_clavier(page, libelle)
  page.click_button('Affichage personnalisé') unless page.has_css?('button.fr-tag', text: libelle, wait: 1)
  bouton = tag(page, libelle)
  avant = bouton['aria-pressed']
  bouton.send_keys(:space)
  page.assert_selector("button.fr-tag[aria-pressed=#{avant == 'true' ? 'false' : 'true'}]", text: libelle)
  page.assert_no_selector('.fr-collapsing')
  raise "focus sur #{page.evaluate_script('document.activeElement.textContent')}" unless page.evaluate_script('document.activeElement.textContent') == libelle
end

def attendre_les_sections(page, panneau, attendu)
  Timeout.timeout(5) { sleep 0.1 until sections_depliees(page, panneau) == attendu }
rescue Timeout::Error
  raise "#{panneau} : #{sections_depliees(page, panneau)} dépliées, attendu #{attendu}"
end

def ouvrir_onglet(page, id)
  page.find("[role=tab][aria-controls=#{id}]").click
  page.assert_selector("##{id}.fr-tabs__panel--selected")
  page.assert_no_selector('.fr-collapsing')
end

ENTETE = <<~JS.freeze
  (() => { const r = document.querySelector('.affichage-personnalise__entete').getBoundingClientRect(); return [Math.round(r.top), Math.round(r.bottom)] })()
JS
BOUTON = 'Affichage personnalisé'.freeze
ANCRES = { 'contexte-et-cadre-juridique' => 'Contexte et cadre juridique', 'donnees-disponibles' => 'Données disponibles et utiles',
           'solutions-integratrices' => 'Solutions ayant intégré ces données' }.freeze
ETAPES_DES_TAGS = [[TAG_SITES, %w[logiciels sites], %w[logiciels sites], 'deux-tags'],
                   [TAG_LOGICIELS, %w[sites], nil, 'second-clic'],
                   [TAG_SITES, [], FILTRES, 'aucun-tag']].freeze

Sections = Struct.new(:donnees, :solutions) do
  def seulement(panneau, choisis) = self[panneau].to_h { |filtre, nombre| [filtre, choisis.include?(filtre) ? nombre : 0] }
end

def entete(page) = page.evaluate_script(ENTETE)
def haut_de(page, selecteur, bord) = page.evaluate_script("document.querySelector('#{selecteur}').getBoundingClientRect().#{bord}").round
def depliees(page) = "onglet1=#{sections_depliees(page, 'donnees-disponibles')} onglet2=#{sections_depliees(page, 'solutions-integratrices')}"

def attendre_la_fin_du_depliage(page)
  Timeout.timeout(3) do
    precedent = nil
    until (actuel = entete(page)) == precedent
      precedent = actuel
      sleep 0.2
    end
  end
end

def tags_a_l_arrivee(page)
  tags = page.all('button.fr-tag').map { "#{it.text}:#{it['aria-pressed']}:#{it.native.aria_role}" }
  raise "tags #{tags}" unless tags.size == 3 && tags.all? { it.end_with?(':false:button') }
  raise 'bouton visible en haut de page' if page.has_button?(BOUTON, wait: 0)

  tags
end

def arrivee(page, demarche)
  page.current_window.resize_to(1280, 1024)
  page.visit("/demarches/#{demarche.slug}")
  tags = tags_a_l_arrivee(page)
  sections = Sections.new(sections(page, 'donnees-disponibles'), sections(page, 'solutions-integratrices'))
  attendre_les_sections(page, 'donnees-disponibles', FILTRES.index_with(0))
  attendre_les_sections(page, 'solutions-integratrices', sections.solutions)
  Verify.evidence(DOSSIER, page, 'arrivee', "slug=#{demarche.slug} tags=#{tags.join(' | ')} totaux=#{sections.to_h}")
  sections
end

def attendre_les_deux_onglets(page, sections, donnees, solutions)
  attendre_les_sections(page, 'donnees-disponibles', sections.seulement(:donnees, donnees))
  attendre_les_sections(page, 'solutions-integratrices', sections.seulement(:solutions, solutions)) if solutions
end

def seulement_les_logiciels(page, sections)
  attendre_les_deux_onglets(page, sections, %w[logiciels], %w[logiciels])
  raise "#{sections_masquees(page)} sections masquées" unless sections_masquees(page).zero?

  Verify.evidence(DOSSIER, page, 'logiciels', "aria-pressed=#{tag(page, TAG_LOGICIELS)['aria-pressed']} masquees=0 #{depliees(page)}")
end

def appuyer_et_attendre(page, sections, etape)
  libelle, donnees, solutions, nom = etape
  basculer_au_clavier(page, libelle)
  attendre_les_deux_onglets(page, sections, donnees, solutions)
  Verify.evidence(DOSSIER, page, nom, "#{libelle}=#{tag(page, libelle)['aria-pressed']} #{depliees(page)}")
end

def api_dans_les_deux_onglets(page, sections)
  basculer_au_clavier(page, TAG_API)
  attendre_les_sections(page, 'donnees-disponibles', sections.seulement(:donnees, %w[api]))
  ouvrir_onglet(page, 'solutions-integratrices')
  attendre_les_sections(page, 'solutions-integratrices', sections.seulement(:solutions, %w[api]))
  ouvrir_onglet(page, 'donnees-disponibles')
  attendre_les_sections(page, 'donnees-disponibles', sections.seulement(:donnees, %w[api]))
  Verify.evidence(DOSSIER, page, 'api-retour-onglet-1', depliees(page))
end

def relacher_api(page, sections)
  basculer_au_clavier(page, TAG_API)
  ouvrir_onglet(page, 'solutions-integratrices')
  attendre_les_sections(page, 'solutions-integratrices', sections.solutions)
  ouvrir_onglet(page, 'donnees-disponibles')
end

def tags(page, sections)
  seulement_les_logiciels(page, sections)
  ETAPES_DES_TAGS.each { appuyer_et_attendre(page, sections, it) }
  api_dans_les_deux_onglets(page, sections)
  relacher_api(page, sections)
end

def defiler_puis_lire_l_entete(page, demarche, largeur, hauteur)
  page.current_window.resize_to(largeur, hauteur)
  page.visit("/demarches/#{demarche.slug}")
  page.execute_script('window.scrollTo(0, 1500)')
  page.assert_no_selector('button.fr-tag')
  haut, bas = entete(page)
  raise "en-tête à #{haut}" unless haut.zero? && page.find('.affichage-personnalise__entete nav.fr-breadcrumb').visible?

  Verify.evidence(DOSSIER, page, "defile-#{largeur}", "scrollY=#{page.evaluate_script('window.scrollY')} entete=#{haut}..#{bas} " \
                                                      "bouton=#{page.find_button(BOUTON).text} tags=replies")
end

def tags_rouverts_sous_le_fil(page)
  page.click_button(BOUTON)
  page.assert_selector('button.fr-tag', count: 3)
  attendre_la_fin_du_depliage(page)
  haut_tag = haut_de(page, 'button.fr-tag', 'top')
  bas_fil = haut_de(page, '.affichage-personnalise__entete nav', 'bottom')
  haut, bas = entete(page)
  raise "tags à #{haut_tag}, fil jusqu'à #{bas_fil}, en-tête #{haut}..#{bas}" unless haut.zero? && haut_tag > bas_fil && haut_tag < bas

  "fil_bas=#{bas_fil} premier_tag=#{haut_tag} entete=#{haut}..#{bas}"
end

def affichage_apres_defilement(page, demarche, largeur, hauteur)
  defiler_puis_lire_l_entete(page, demarche, largeur, hauteur)
  positions = tags_rouverts_sous_le_fil(page)
  basculer_au_clavier(page, TAG_LOGICIELS)
  basculer_au_clavier(page, TAG_SITES)
  page.assert_selector(:button, text: /#{BOUTON}[[:space:]]+\(2\)/)
  Verify.evidence(DOSSIER, page, "bouton-rouvre-#{largeur}", "bouton=#{page.find_button(BOUTON).text} #{positions}")
  page.execute_script('window.scrollTo(0, 0)')
  page.assert_selector('button.fr-tag[aria-pressed=true]', count: 2)
end

def cible_sous_l_entete(page, id, etape)
  attendre_la_fin_du_depliage(page)
  bas = entete(page).last
  haut = haut_de(page, "##{id}", 'top')
  raise "#{etape} : ##{id} à #{haut}, sous l’en-tête jusqu’à #{bas}" if haut < bas

  Verify.evidence(DOSSIER, page, etape, "cible=##{id} entete_bas=#{bas} cible_haut=#{haut}")
end

def ancre_par_le_sommaire_puis_a_l_arrivee(page, demarche, id, largeur)
  page.visit("/demarches/#{demarche.slug}")
  page.find('nav.fr-summary').click_link(ANCRES[id])
  cible_sous_l_entete(page, id, "ancre-sommaire-#{id}-#{largeur}")
  page.visit("/demarches/#{demarche.slug}##{id}")
  cible_sous_l_entete(page, id, "ancre-arrivee-#{id}-#{largeur}")
end

def affichage_ancres(page, demarche, largeur)
  page.current_window.resize_to(largeur, 1024)
  ANCRES.each_key { ancre_par_le_sommaire_puis_a_l_arrivee(page, demarche, it, largeur) }
  page.execute_script('window.scrollTo(0, 2500)')
  page.click_button(BOUTON)
  page.assert_selector('button.fr-tag', count: 3)
  page.execute_script("location.hash = '#contexte-et-cadre-juridique'")
  cible_sous_l_entete(page, 'contexte-et-cadre-juridique', "ancre-bandeau-ouvert-#{largeur}")
end

def defiler_lentement(page)
  15.times.map do
    page.execute_script('window.scrollBy(0, 40)')
    sleep 0.4
    page.evaluate_script('Math.round(window.scrollY)')
  end
end

def defilement_lent_a(page, demarche, largeur, hauteur)
  page.current_window.resize_to(largeur, hauteur)
  page.visit("/demarches/#{demarche.slug}")
  page.assert_selector('button.fr-tag', count: 3)
  positions = defiler_lentement(page)
  raise "défilement lent à #{largeur} px bloqué : #{positions.join(' ')}" if positions.last < 300

  Verify.evidence(DOSSIER, page, "defilement-lent-#{largeur}", "scrollY=#{positions.join(' ')}")
end

def affichage_defilement_lent(page, demarche)
  [[1280, 1024], [375, 800]].each { |largeur, hauteur| defilement_lent_a(page, demarche, largeur, hauteur) }
  page.current_window.resize_to(1280, 1024)
end

def affichage_par_turbo(page, demarche)
  page.visit('/demarches')
  page.execute_script("Turbo.visit('/demarches/#{demarche.slug}')")
  page.assert_current_path("/demarches/#{demarche.slug}")
  page.assert_selector('h1', text: demarche.titre)
  basculer_au_clavier(page, TAG_SITES)
  raise 'aucune section des sites dépliée' if sections_depliees(page, 'donnees-disponibles')['sites'].zero?

  page.execute_script('window.scrollTo(0, 1500)')
  page.assert_selector(:button, text: /#{BOUTON}[[:space:]]+\(1\)/)
  Verify.evidence(DOSSIER, page, 'turbo', "apres_visite_turbo onglet1=#{sections_depliees(page, 'donnees-disponibles')}")
end

def page_sans_debord(page)
  largeurs = page.evaluate_script('[document.documentElement.scrollWidth, document.documentElement.clientWidth]')
  raise "la page déborde : #{largeurs}" if largeurs[0] > largeurs[1]

  largeurs.join('/')
end

def entete_hors_de_vue(page)
  haut, bas = entete(page)
  raise "en-tête collé à #{haut} sur téléphone" unless haut.negative?

  "#{haut}..#{bas}"
end

def affichage_mobile(page, demarche)
  page.current_window.resize_to(375, 800)
  page.visit("/demarches/#{demarche.slug}")
  page.execute_script('window.scrollTo(0, 2500)')
  sleep 0.5
  raise 'bouton visible sur téléphone' if page.has_button?(BOUTON, wait: 0)

  Verify.evidence(DOSSIER, page, 'mobile', "page=#{page_sans_debord(page)} entete=#{entete_hors_de_vue(page)} bouton=absent")
  page.current_window.resize_to(1280, 1024)
end

def affichage_sans_js(demarche)
  page = Verify.session(javascript: false)
  page.visit("/demarches/#{demarche.slug}")
  raise 'tags affichés sans JS' if page.has_css?('button.fr-tag', wait: 0)
  raise 'bouton affiché sans JS' if page.has_button?(BOUTON, wait: 0)

  volets = page.evaluate_script("[...document.querySelectorAll('[data-filtre] > :is(#{VOLET})')].map((volet) => volet.checkVisibility())")
  raise "sans JS, #{volets.count(false)} sections cachées" unless volets.any? && volets.all?

  Verify.evidence(DOSSIER, page, 'sans-js', "tags=absents bouton=absent sections_lisibles=#{volets.size}/#{volets.size}")
ensure
  page&.quit
end

def lignes_de_ce_passage(debut)
  lignes = Verify::ROOT.join(DOSSIER, 'read-back.txt').readlines.select { it >= debut && it.include?(" #{Verify.browser} ") }
  raise 'read-back.txt sans ligne de ce passage' if lignes.empty?
end

Verify.drive(__FILE__) do |page|
  debut = Time.now.utc.iso8601
  demarche = Demarche.visibles.order(:id).find { it.integratrices_par_categorie.size > 1 }
  sections = Verify.check('Arrival') { arrivee(page, demarche) }
  Verify.check('Keyboard') { basculer_au_clavier(page, TAG_LOGICIELS) }
  Verify.check('Tags') { tags(page, sections) }
  Verify.check('Scroll') { [[1280, 1024], [800, 1024]].each { |largeur, hauteur| affichage_apres_defilement(page, demarche, largeur, hauteur) } }
  Verify.check('Anchors') { [1280, 800].each { |largeur| affichage_ancres(page, demarche, largeur) } }
  Verify.check('Slow scroll') { affichage_defilement_lent(page, demarche) }
  Verify.check('Turbo') { affichage_par_turbo(page, demarche) }
  Verify.check('Mobile') { affichage_mobile(page, demarche) }
  Verify.check('No JS') do
    page.quit
    affichage_sans_js(demarche)
  end
  Verify.check('Proof') { lignes_de_ce_passage(debut) }
end
