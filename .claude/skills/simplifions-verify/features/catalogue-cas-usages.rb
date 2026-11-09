require_relative '../harness'

def etiquettes(page, groupe) = page.find(:xpath, "//p[normalize-space()='#{groupe} :']/following-sibling::ul[1]")

def compte(page) = page.find('[role=status]').text[/\d+/].to_i

def cliquer_tag(page, groupe, libelle)
  tag = etiquettes(page, groupe).find(:button, text: /\A#{libelle} \(\d+\)\z/)
  annonce = tag.text[/\((\d+)\)/, 1].to_i
  tag.click
  annonce
end

def focus_sur_les_resultats(page) = page.assert_selector('#resultats', focused: true)

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

def replis_sans_javascript
  page = Verify.session(javascript: false)
  page.visit('/demarches?types-de-simplification=dlnuf')
  choisi = page.find(:xpath, "//details[@open][summary[normalize-space()='Plus de filtres']]").find('button[aria-pressed=true]').text
  page.find('summary', text: 'Afficher les 5 autres').click
  page.find(:button, text: /\ATous les acteurs publics \(\d+\)\z/)
  Verify.evidence('catalogue-cas-usages', page, 'sans-js', "choisi_visible=#{choisi} autres_acteurs=ouverts")
ensure
  page&.quit
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
    annonce = cliquer_tag(page, 'Démarches à destination des', 'Entreprises')
    page.assert_current_path(/target-users=entreprises/, url: false)
    focus_sur_les_resultats(page)
    raise "tag annonçait #{annonce}, liste #{compte(page)}" unless annonce == compte(page)

    compte(page)
  end

  Verify.check('Proof') do
    attendu = Demarche.catalogue({ 'q' => 'marchés publics', 'target-users' => 'entreprises' }).count
    raise "compte #{facette} != base #{attendu}" unless facette == attendu

    Verify.evidence('catalogue-cas-usages', page, 'filtre',
      "total=#{total} recherche=#{recherche} recherche+entreprises=#{facette} base=#{attendu}")
  end

  cumul = Verify.check('Several') do
    cliquer_tag(page, 'Démarches à destination des', 'Associations')
    page.assert_current_path(/target-users=entreprises%2Cassociations/, url: false)
    attendu = Demarche.catalogue({ 'q' => 'marchés publics', 'target-users' => 'entreprises,associations' }).count
    raise "cumul #{compte(page)} != base #{attendu} ou < #{facette}" unless compte(page) == attendu && attendu >= facette

    Verify.evidence('catalogue-cas-usages', page, 'cumul', "entreprises=#{facette} entreprises+associations=#{attendu}")
    attendu
  end

  Verify.check('Actor') do
    page.find(:button, text: /\ACommunes et groupements \(\d+\)\z/).click
    page.assert_current_path(/fournisseurs-de-service=communes/, url: false)
    focus_sur_les_resultats(page)
    attendu = Demarche.catalogue({ 'q' => 'marchés publics', 'target-users' => 'entreprises,associations',
                                   'fournisseurs-de-service' => 'communes' }).count
    raise "acteur #{compte(page)} != base #{attendu}" unless compte(page) == attendu

    Verify.evidence('catalogue-cas-usages', page, 'acteur', "cumul+communes=#{attendu}")
  end

  Verify.check('Show more') do
    deplier = page.find('summary', text: 'Afficher les 5 autres')
    raise 'déjà ouvert' if page.has_css?('details[open] > summary', text: 'Afficher les 5 autres')

    deplier.click
    page.find(:button, text: /\ATous les acteurs publics \(\d+\)\z/).click
    page.assert_current_path(/fournisseurs-de-service=communes%2Ctout-acteurs-publics/, url: false)
    raise 'les autres acteurs se sont refermés' unless page.has_css?('details[open] > summary', text: 'Afficher les 5 autres')

    attendu = Demarche.catalogue({ 'q' => 'marchés publics', 'target-users' => 'entreprises,associations',
                                   'fournisseurs-de-service' => 'communes,tout-acteurs-publics' }).count
    raise "acteurs #{compte(page)} != base #{attendu}" unless compte(page) == attendu

    Verify.evidence('catalogue-cas-usages', page, 'afficher-plus', "communes+tous-acteurs-publics=#{attendu}")
  end

  Verify.check('Remove') do
    page.all('button[aria-pressed=true]').size.times do
      page.first('button[aria-pressed=true]').click
      focus_sur_les_resultats(page)
    end
    page.assert_no_selector('button[aria-pressed=true]')
    raise "après retrait : #{compte(page)} != recherche #{recherche}" unless compte(page) == recherche

    Verify.evidence('catalogue-cas-usages', page, 'retrait', "recherche=#{recherche} cumul=#{cumul} apres_retrait=#{compte(page)}")
  end

  Verify.check('Sort') do
    raise 'Trier visible avant tout changement' if page.has_button?('Trier', wait: 0.5)

    page.select 'Date de création', from: 'Trier par :'
    page.assert_selector(:button, 'Trier')
    page.select 'Pertinence', from: 'Trier par :'
    page.assert_no_selector(:button, 'Trier')
    page.select 'Date de création', from: 'Trier par :'
    page.click_button 'Trier'
    page.assert_current_path(/sort=-created/, url: false)
    page.assert_no_selector(:button, 'Trier')
    Verify.evidence('catalogue-cas-usages', page, 'tri', "url=#{page.current_url[/\?.*/]} bouton_trier=cache")
  end

  Verify.check('Type height') { hauteur_des_types(page) }
  Verify.check('Without JavaScript') do
    page.quit
    replis_sans_javascript
  end
end
