require_relative '../harness'

DOSSIER = 'couleurs-dsfr'.freeze

STYLES_LUS = <<~JS.freeze
  ((regles) => {
    const visible = it => it.offsetParent !== null || getComputedStyle(it).position === 'fixed'
    const sonde = document.body.appendChild(document.createElement('div'))
    const lus = regles.flatMap(([selecteur, propriete, valeur]) => {
      sonde.style.cssText = `${propriete}: ${valeur}`
      const attendu = getComputedStyle(sonde).getPropertyValue(propriete)
      return [...document.querySelectorAll(selecteur)].filter(visible)
        .map(it => ({ selecteur, attendu, lu: getComputedStyle(it).getPropertyValue(propriete) }))
    })
    sonde.remove()
    return lus
  })(arguments[0])
JS

PASTILLES = {
  'green' => 'var(--background-contrast-success)',
  'yellow' => 'var(--background-contrast-green-tilleul-verveine)',
  'orange' => 'var(--background-action-low-yellow-moutarde)',
  'red' => 'var(--background-action-low-red-marianne)'
}.map { |couleur, jeton| [".integration-indicator__count.indicator--#{couleur}", 'background-color', jeton] }

BOUTON_FLOTTANT = ['.bouton-proposer-modification', 'box-shadow',
                   'inset 0 0 0 1px var(--border-action-high-blue-france), var(--overlap-shadow)'].freeze
ACCUEIL = [['.banner .card', 'box-shadow', 'var(--raised-shadow)']].freeze
CATALOGUE = [['.demarche-card .header-topic', 'background-color', 'var(--background-contrast-blue-cumulus)'],
             ['.demarche-card .header-topic', 'color', 'var(--text-label-blue-cumulus)'],
             ['.demarche-card .title-topic', 'color', 'var(--text-label-blue-cumulus)']].freeze
CAS_USAGE = PASTILLES + [BOUTON_FLOTTANT]
PERIMETRE = [['.solution-page .fr-icon-stop-circle-fill', 'color', 'var(--text-mention-grey)'], BOUTON_FLOTTANT].freeze
INTEGRATRICES = PASTILLES + [['#solutions-integratices', 'background-color', 'var(--background-contrast-grey)']]
ARTICLE = [['.article-screenshot', 'box-shadow', 'var(--raised-shadow)']].freeze

def ecran(page, nom, chemin, regles, cible)
  page.visit(chemin)
  lire(page, nom, regles, cible)
end

def lire(page, nom, regles, cible)
  lus = page.evaluate_script(STYLES_LUS, regles)
  absents = sans_element_visible(regles, lus)
  raise "#{nom} : rien de visible pour #{absents}" if absents.any?

  capturer(page, nom, cible, lus)
  lus.reject { it['lu'] == it['attendu'] }.map { "#{nom} #{it['selecteur']} lu=#{it['lu']} attendu=#{it['attendu']}" }.uniq
end

def sans_element_visible(regles, lus)
  (regles - PASTILLES).map(&:first).reject { |selecteur| lus.any? { it['selecteur'] == selecteur } }
end

def capturer(page, nom, cible, lus)
  { 'bureau' => 1280, 'mobile' => 375 }.each do |format, largeur|
    page.current_window.resize_to(largeur, 1024)
    page.scroll_to(page.first(cible), align: :center)
    Verify.evidence(DOSSIER, page, "#{nom}-#{format}", "largeur=#{largeur} #{lus.map(&:values).uniq}")
  end
ensure
  page.current_window.resize_to(1280, 1024)
end

def demarche_aux_pastilles_variees
  Demarche.visibles.where.not(slug: nil).max_by do |demarche|
    demarche.integratrices.map { demarche.couverture(it) }.reject { it.last.zero? }
      .map { ApplicationController.helpers.couleur_integration(*it) }.uniq.size
  end
end

def solution_non_couverte
  Solution.visibles.where.not(slug: nil).select { it.ne_permet_pas.present? }.max_by { it.integratrices_visibles.count }
end

def ouvrir_les_solutions_integratrices(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  page.find('[role=tab][aria-controls=solutions-integratrices]').click
  page.assert_selector '#solutions-integratrices.fr-tabs__panel--selected .integration-indicator__count'
end

Verify.drive(__FILE__) do |page|
  ecarts = []
  Verify.check('Accueil') { ecarts += ecran(page, 'accueil', '/', ACCUEIL, '.banner .card') }
  Verify.check('Catalogue') { ecarts += ecran(page, 'catalogue', '/demarches', CATALOGUE, '.demarche-card') }

  Verify.check('Cas d’usage') do
    ouvrir_les_solutions_integratrices(page, demarche_aux_pastilles_variees)
    ecarts += lire(page, 'cas-usage', CAS_USAGE, '#solutions-integratrices .integration-indicator')
  end

  Verify.check('Solution') do
    ecarts += ecran(page, 'solution-perimetre', "/solutions/#{solution_non_couverte.slug}", PERIMETRE, '.solution-page .fr-icon-stop-circle-fill')
    ecarts += lire(page, 'solution-integratrices', INTEGRATRICES, '.cas-usage-card')
  end

  Verify.check('Article') { ecarts += ecran(page, 'article', '/articles/qu-est-ce-qu-une-api', ARTICLE, '.article-screenshot') }

  Verify.check('Couleurs DSFR') do
    Verify.evidence(DOSSIER, page, 'bilan', "ecarts=#{ecarts}")
    raise ecarts.join(' | ') if ecarts.any?
  end
end
