require_relative '../harness'

FLECHE = <<~JS.freeze
  (() => {
    const fleche = [...document.querySelectorAll('.solution-integratrice-card__arrow')].find(it => it.offsetParent)
    return [getComputedStyle(fleche).position, getComputedStyle(fleche.querySelector('.fr-icon-arrow-right-line')).color]
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
  Verify.check('Proof') { Verify.captures_presentes('fiche-solution', %w[dernier-onglet fleche-carte]) }
end
