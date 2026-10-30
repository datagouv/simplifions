require_relative '../harness'

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
    page.assert_current_path(/target-users=entreprises/, url: false)
    page.find('[role=status]').text[/\d+/].to_i
  end

  Verify.check('Proof') do
    attendu = Demarche.catalogue({ 'q' => 'marchés publics', 'target-users' => 'entreprises' }).count
    raise "compte #{facette} != base #{attendu}" unless facette == attendu

    Verify.evidence('catalogue-cas-usages', page, 'filtre',
      "total=#{total} recherche=#{recherche} recherche+entreprises=#{facette} base=#{attendu}")
  end
end
