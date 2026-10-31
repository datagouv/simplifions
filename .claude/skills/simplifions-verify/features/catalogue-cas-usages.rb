require_relative '../harness'

def titres_des_filtres(page)
  { '/solutions' => 'Filtrer les solutions', '/demarches' => "Filtrer les cas d'usages" }.each do |chemin, titre|
    page.visit(chemin)
    h2 = page.find('h2', text: titre, exact_text: true, visible: :all)
    largeur = page.evaluate_script('arguments[0].getBoundingClientRect().width', h2)
    ecart = page.evaluate_script("document.querySelector('.fr-search-bar').getBoundingClientRect().top - document.querySelector('h1').getBoundingClientRect().bottom")
    raise "#{chemin} : titre de #{largeur} px, #{ecart.round} px entre le H1 et la recherche" unless largeur <= 1 && ecart < 60

    Verify.evidence('catalogue-cas-usages', page, "titre#{chemin.tr('/', '-')}", "#{chemin} titre_filtres=sr-only ecart_h1_recherche=#{ecart.round}px")
  end
end

Verify.drive(__FILE__) do |page|
  total = Verify.check('Open the list') do
    page.visit('/demarches')
    page.assert_selector 'h1', text: "Cas d'usages"
    page.find('[role=status]').text[/\d+/].to_i.tap { raise 'catalogue vide' unless it.positive? }
  end

  Verify.check('Filter heading') { titres_des_filtres(page) }

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
end
