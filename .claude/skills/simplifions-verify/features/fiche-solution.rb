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
  Verify.check('Proof') { Verify.captures_presentes('fiche-solution', %w[dernier-onglet fleche-carte image-exemple]) }
end
