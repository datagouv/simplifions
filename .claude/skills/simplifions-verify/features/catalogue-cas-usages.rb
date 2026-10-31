require_relative '../harness'

def hauteur_des_types(page)
  page.current_window.resize_to(390, 844)
  page.visit('/demarches')
  hauteur = ->(element) { page.evaluate_script('arguments[0].getBoundingClientRect().height', element).round }
  tri = hauteur.call(page.find_field('Trier par :'))
  types = page.find(:xpath, "//p[normalize-space()='Type']/following-sibling::ul[1]").all('a').map(&hauteur)
  Verify.evidence('catalogue-cas-usages', page, 'type-390', "trier_par=#{tri} types=#{types}")
  raise "types #{types} != trier par #{tri}" unless types.size == 2 && types.all?(tri)
ensure
  page.current_window.resize_to(1280, 1024)
end

Verify.drive(__FILE__) do |page|
  total = Verify.check('Open the list') do
    page.visit('/demarches')
    page.assert_selector 'h1', text: "Cas d'usages"
    page.find('[role=status]').text[/\d+/].to_i.tap { raise 'catalogue vide' unless it.positive? }
  end

  recherche = Verify.check('Search') do
    page.fill_in 'Recherche', with: 'marchés publics'
    page.click_button 'Recherche'
    page.assert_current_path(/q=march/, url: false)
    page.find('[role=status]').text[/\d+/].to_i
  end

  facette = Verify.check('Facet') do
    page.select 'Entreprises', from: 'Démarches à destination des :'
    page.click_button 'Appliquer les filtres'
    page.assert_current_path(/target-users=entreprises/, url: false)
    page.find('[role=status]').text[/\d+/].to_i
  end

  Verify.check('Proof') do
    attendu = Demarche.catalogue({ 'q' => 'marchés publics', 'target-users' => 'entreprises' }).count
    raise "compte #{facette} != base #{attendu}" unless facette == attendu

    Verify.evidence('catalogue-cas-usages', page, 'filtre',
      "total=#{total} recherche=#{recherche} recherche+entreprises=#{facette} base=#{attendu}")
  end

  Verify.check('Type height') { hauteur_des_types(page) }
end
