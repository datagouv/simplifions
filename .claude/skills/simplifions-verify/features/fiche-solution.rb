require_relative '../harness'

FLECHE = <<~JS.freeze
  (() => {
    const fleche = [...document.querySelectorAll('.solution-integratrice-card__arrow')].find(it => it.offsetParent)
    return [getComputedStyle(fleche).position, getComputedStyle(fleche.querySelector('.fr-icon-arrow-right-line')).color]
  })()
JS

IMAGE_EXEMPLE = <<~JS.freeze
  (() => {
    const cadre = getComputedStyle(document.querySelector('.example-image'))
    const image = getComputedStyle(document.querySelector('.example-image img'))
    return [image.borderTopLeftRadius, cadre.borderTopWidth, cadre.borderTopColor, cadre.boxShadow !== 'none']
  })()
JS

def onglets_attendus(solution)
  solution.integratrices_par_categorie
    .map { |categorie, solutions| "#{I18n.t("public.onglets_integratrices.#{categorie}")} (#{solutions.size})" }
end

def fleche_de_carte(page)
  page.assert_selector '[role=tabpanel] .solution-integratrice-card__arrow'
  style = page.evaluate_script(FLECHE)
  raise "flèche #{style}" unless style == ['absolute', 'rgb(0, 0, 145)']

  Verify.evidence('fiche-solution', page, 'fleche-carte', "position=#{style.first} couleur=#{style.last}")
end

def image_exemple(page)
  solution = Solution.visibles.where.not(slug: nil).joins(:image_attachment).order(:slug).first
  page.visit("/solutions/#{solution.slug}")
  page.assert_selector '.example-image img'
  style = page.evaluate_script(IMAGE_EXEMPLE)
  raise "image #{style}" unless style == ['0px', '4px', 'rgb(0, 0, 0)', true]

  page.scroll_to(page.find('figure.fr-content-media'), align: :center)
  Verify.evidence('fiche-solution', page, 'image-exemple', "slug=#{solution.slug} coin, cadre, couleur, ombre=#{style}")
end

ZONE_CAS_USAGES = %([data-matomo-zone="Solution › Cas d'usages simplifiables"]).freeze

def vers_les_solutions(solution) = ['Comparer avec les autres solutions', %(Solutions intégrant "#{solution.nom}" pour cette démarche)]

def lien_vers_les_solutions(carte) = carte.all('a').map { it.text.squish.sub(/ ?: .*\z/, '') }.find { it.start_with?('Comparer', 'Solutions intégrant') }

def cartes_lues(page)
  page.find(ZONE_CAS_USAGES).all('.demarche-card').map do |carte|
    [carte.find('h3').text, carte.has_css?('h3 a', wait: 0), carte.has_link?('Consulter la démarche', wait: 0), lien_vers_les_solutions(carte)]
  end
end

def lien_attendu(solution, demarche)
  return unless demarche.integratrices_par_categorie.any?

  vers_les_solutions(solution)[demarche.id.in?(solution.demarche_ids_recommandantes) ? 1 : 0]
end

def cartes_attendues(solution) = solution.demarches_simplifiables.map { [it.titre, false, true, lien_attendu(solution, it)] }

def fond_au_survol(page, carte)
  fond = -> { page.evaluate_script('getComputedStyle(arguments[0]).backgroundColor', carte) }
  avant = fond.call
  carte.hover
  [avant, fond.call]
end

def hauteurs_par_rangee(page)
  page.evaluate_script(<<~JS).values
    [...document.querySelectorAll('.demarche-card--liens')].reduce((rangees, carte) => {
      const { top, height } = carte.getBoundingClientRect()
      const liens = carte.querySelector('.demarche-card__liens').getBoundingClientRect()
      const bleu = carte.querySelector('.header-topic').getBoundingClientRect()
      ;(rangees[Math.round(top)] ||= []).push(`${Math.round(height)}:${Math.round(bleu.height)}:${Math.round(liens.bottom - top)}`)
      return rangees
    }, {})
  JS
end

def cartes_de_cas_usage(page, solution)
  page.current_window.resize_to(1280, 1024)
  page.visit("/solutions/#{solution.slug}")
  attendues = cartes_attendues(solution)
  raise "cartes #{cartes_lues(page)} au lieu de #{attendues}" unless cartes_lues(page) == attendues
  raise 'carte encore cliquable en entier' if page.find(ZONE_CAS_USAGES).has_css?('.fr-enlarge-link', wait: 0)

  hauteurs = hauteurs_par_rangee(page)
  raise "cartes ou liens pas alignés dans une rangée (hauteur:en-tête bleu:bas des liens) : #{hauteurs}" unless hauteurs.all? { it.uniq.size == 1 }

  page.scroll_to(page.find(ZONE_CAS_USAGES), align: :top)
  avant, apres = fond_au_survol(page, page.find(ZONE_CAS_USAGES).first('.demarche-card'))
  raise "le fond change au survol : #{avant} → #{apres}" unless avant == apres

  Verify.evidence('fiche-solution', page, 'tuiles-ordinateur',
    "slug=#{solution.slug} cartes=#{attendues.size} liens=#{attendues.map(&:last).tally} sans_lien=#{attendues.reject(&:last).map(&:first)} fond_survol=#{apres} hauteurs_par_rangee=#{hauteurs}")
end

def comparer_depuis_une_carte(page)
  carte = page.find(ZONE_CAS_USAGES).all('.demarche-card').find { lien_vers_les_solutions(it) }
  titre = carte.find('h3').text
  libelle = lien_vers_les_solutions(carte)
  carte.click_link(libelle)
  page.assert_selector '#solutions-integratrices.fr-tabs__panel--selected'
  demarche = Demarche.find_by!(slug: page.current_path.delete_prefix('/demarches/'))
  vue = page.find_field('Tableau comparatif', visible: :all).checked?
  raise "vue tableau=#{vue}, tableau utile=#{demarche.tableau_comparatif_utile?}" unless vue == demarche.tableau_comparatif_utile?

  Verify.evidence('fiche-solution', page, 'apres-comparer', "carte=#{titre.inspect} page=#{page.current_path} lien=#{libelle.inspect} onglet=Solutions tableau=#{vue}")
end

def cartes_sur_telephone(page, solution)
  page.current_window.resize_to(375, 800)
  page.visit("/solutions/#{solution.slug}")
  lien = page.find(ZONE_CAS_USAGES).first(:link, 'Consulter la démarche')
  page.scroll_to(lien.ancestor('.demarche-card'), align: :top)
  largeurs = page.evaluate_script('[document.documentElement.scrollWidth, document.documentElement.clientWidth]')
  raise "la page déborde : #{largeurs}" if largeurs.first > largeurs.last

  Verify.evidence('fiche-solution', page, 'tuiles-telephone', "largeur=#{largeurs.join('/')}")
end

def solution_aux_deux_cas
  Solution.visibles.where.not(slug: nil).select { |solution| solution.demarches_simplifiables.any? { it.integratrices_par_categorie.empty? } }
    .max_by { it.demarches_simplifiables.size }
end

Verify.drive(__FILE__) do |page|
  solution = Solution.visibles.where.not(slug: nil).max_by { |candidate| candidate.integratrices_par_categorie.size }
  onglets = onglets_attendus(solution)

  Verify.check('Open') do
    page.visit("/solutions/#{solution.slug}")
    page.assert_text(/Solution (publique|privée) \|/i)
  end

  textes = Verify.check('Tabs') do
    page.all('[role=tab]').map(&:text).tap { |textes| raise "onglets #{textes} au lieu de #{onglets}" unless textes == onglets }
  end

  Verify.check('Switch') do
    page.all('[role=tab]').last.click
    page.assert_selector "[role=tab][aria-selected='true']", text: onglets.last
    Verify.evidence('fiche-solution', page, 'dernier-onglet', "slug=#{solution.slug} onglets=#{textes} attendus=#{onglets}")
  end

  Verify.check('Card arrow') { fleche_de_carte(page) }
  Verify.check('Example image') { image_exemple(page) }
  aux_deux_cas = solution_aux_deux_cas
  Verify.check("Cas d'usage cards") { cartes_de_cas_usage(page, aux_deux_cas) }
  Verify.check('Compare from a card') { comparer_depuis_une_carte(page) }
  Verify.check("Cas d'usage cards on a phone") { cartes_sur_telephone(page, aux_deux_cas) }
  Verify.check('Proof') { Verify.captures_presentes('fiche-solution', %w[dernier-onglet fleche-carte image-exemple tuiles-ordinateur apres-comparer tuiles-telephone]) }
end
