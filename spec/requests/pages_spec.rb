RSpec.describe 'Pages' do
  describe 'GET /' do
    it 'renders the homepage mirroring simplifions.data.gouv.fr' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Le catalogue des données')
      expect(response.body).to include('fr-header')
      expect(response.body).to include('fr-footer')
    end

    it 'mène au contenu par le premier lien de la page' do
      get root_path

      premier_lien = response.parsed_body.at_css('body a')
      expect(premier_lien.text).to eq('Contenu')
      expect(premier_lien['href']).to eq('#content')
    end

    it 'affiche les logos datagouv et numerique.gouv dans le bloc marque du pied de page' do
      get root_path

      expect(response.body).not_to include('fr-footer__brand fr-enlarge-link')
      expect(response.body).to include('href="https://www.data.gouv.fr/products"')
      expect(response.body).to include('Produit de l’écosystème datagouv')
      expect(response.body).to include('href="https://www.numerique.gouv.fr/"')
      expect(response.body).to include('alt="numerique.gouv - L’alliance du numérique de l’État"')
    end

    it 'propose dans le pied de page les liens d’aide et ceux du site' do
      get root_path

      expect(response.body).to include('fr-footer__top')
      expect(response.parsed_body.css('.fr-footer__top-cat').map(&:text)).to eq(
        ['Démarches référencées à destination des :', 'Démarches référencées gérées par les :',
         '3 guides pour débuter :', 'Découvrir les solutions raccordées aux données :',
         'Comparer le nombre de données raccordées par solution :',
         'Simplifions.data.gouv.fr', 'Aide', 'Contribution']
      )
      expect(response.body).to include('href="/contact/probleme-site">Signaler un problème sur le site</a>')
      expect(response.body).to include('href="/contact/contenu">Proposer une modification de contenu</a>')
      expect(response.body).to include('href="/contact/nouveau-cas-usage">Demander le référencement d&#39;une démarche</a>')
      expect(response.body).to include('href="/contact/nouvelle-solution">Demander le référencement d&#39;une solution</a>')
      expect(response.body).to include('href="/contact">Nous contacter</a>')
      expect(response.body).to include('href="/about">À propos</a>')
      expect(response.body).to include('href="/#redaction-contenu">Comment est rédigé le contenu ?</a>')
    end

    it 'ouvre depuis le pied de page le catalogue filtré, les guides et les comparatifs' do
      get root_path

      liens = response.parsed_body.css('.fr-footer__top-link').to_h { |lien| [lien.text, lien['href']] }
      expect(liens).to include(
        'Particuliers' => '/demarches?target-users=particuliers',
        'Entreprises' => '/demarches?target-users=entreprises',
        'Associations' => '/demarches?target-users=associations',
        'Communes et groupements de communes' => '/demarches?fournisseurs-de-service=communes',
        'Départements' => '/demarches?fournisseurs-de-service=departements',
        'Régions' => '/demarches?fournisseurs-de-service=regions',
        'État' => '/demarches?fournisseurs-de-service=etat',
        'Acteurs du transport' => '/demarches?fournisseurs-de-service=acteurs-transport',
        "Acteurs de l'éducation et de l'enseignement" => '/demarches?fournisseurs-de-service=acteurs-education-enseignement',
        'Guide de base pour les collectivités' => '/articles/guide-base-petites-collectivites',
        "Qu'est-ce qu'une API ?" => '/articles/qu-est-ce-qu-une-api',
        "Prérequis et étapes d'intégration d'une API" => '/articles/prerequis-et-etapes-integration-api',
        'Sites de consultation en ligne' => '/solutions?categorie-de-solution=portail-consultation',
        "Logiciel métier «\u00a0clé en main\u00a0»" => '/solutions?categorie-de-solution=logiciel-metier',
        'API, jeu de données ou brique logicielle' => '/solutions?categorie-de-solution=brique-technique',
        "Solutions ayant intégré l'API Entreprise" => '/solutions/bouquet-api-entreprise#solutions-integratices',
        "Solutions ayant intégré l'API Particulier" => '/solutions/bouquet-api-particulier#solutions-integratices'
      )
    end

    it 'présente le site dans le pied de page et renvoie vers ce qu’il apporte, sur l’accueil' do
      get root_path

      presentation = response.parsed_body.at_css('.fr-footer__content-desc')
      expect(presentation.at_css('strong').text).to eq(
        'Ce site est un catalogue des données accessibles aux acteurs publics organisé par démarche usagers.'
      )
      expect(presentation.at_css('em').text).to eq('—aides et subventions, marchés publics, petite enfance, cantine, transport, etc.—')
      expect(presentation.text.squish).to include(
        'le catalogue recense les API et bases de données utiles, les solutions publiques et privées raccordées ' \
        'à ces données, et les sites de consultation de ces données disponibles en ligne.'
      )
      expect(presentation.at_css('a').text).to eq('En quoi simplifions.data.gouv.fr peut-il vous aider ?')
      expect(presentation.at_css('a')['href']).to eq('/#comment-vous-aider')
      expect(response.parsed_body.at_css('#comment-vous-aider').text).to include('Comment simplifions.data peut-il vous aider')
    end

    it 'présente la page de contact, et non des espaces de discussion disparus, comme moyen de contribuer' do
      get root_path
      expect(response.body).to include('Une page de contact guidée permet aux usagers')
      expect(response.body).not_to include('De nombreux espaces sont disponibles')
    end
  end

  describe 'mesure Matomo de la page d’accueil' do
    it 'range chaque geste de l’accueil dans sa zone' do
      get root_path
      page = Capybara.string(response.body)
      zone = ->(element) { element.find(:xpath, 'ancestor::*[@data-matomo-zone][1]')['data-matomo-zone'] }
      mesure = ->(element) { [zone.call(element), element['data-matomo-action'], element['data-matomo-nom']] }

      expect(mesure.call(page.find('select#select-target-users'))).to eq(['Accueil › Explorer le catalogue', 'Choisir un public', nil])
      expect(page.find('select#select-fournisseurs')['data-matomo-action']).to eq("Choisir un type d'acteur")
      expect(page.find('form.explorateur button')['data-matomo-action']).to eq('Explorer les démarches')
      expect(mesure.call(page.find_link('👱 Particuliers')))
        .to eq(['Accueil › Par public', 'Voir les démarches par public', 'Particuliers'])
      expect(mesure.call(page.find_link('A propos de simplifions.data')))
        .to eq(['Accueil › Présentation', 'Aller à À propos', nil])
      expect(page.find_link('Comment est rédigé le contenu ?', match: :first)['data-matomo-action'])
        .to eq('Lire comment est rédigé le contenu')
      expect(zone.call(page.find('a[data-matomo-action="Lire la doctrine des solutions"]'))).to eq('Accueil › Rédaction du contenu')
      expect(page.all('a[data-matomo-action="Proposer un contenu"]').size).to eq(1)
      expect(zone.call(page.find('a[data-matomo-action="Explorer le catalogue"]'))).to eq('Accueil › Appel final')
    end
  end

  describe 'explorateur de la page d’accueil' do
    it 'envoie vers /demarches avec les facettes du site' do
      Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')

      get root_path

      expect(response.body).to include('<form class="explorateur" action="/demarches" accept-charset="UTF-8" method="get">')
      expect(response.parsed_body.at_css('select#select-target-users')['name']).to eq('target-users')
      expect(response.body).to include('<option value="">particuliers, entreprises, associations</option>')
      expect(response.body).to include('<option value="particuliers">Particuliers</option>')
      expect(response.parsed_body.at_css('select#select-fournisseurs')['name']).to eq('fournisseurs-de-service')
      expect(response.body).to include('<option value="communes">Communes et groupements de communes</option>')
      expect(response.parsed_body.at_css('form.explorateur button[type=submit]').text.squish).to eq('Explorer les démarches référencées')
      expect(response.body).not_to include('href="#" class="fr-btn fr-btn--icon-right fr-icon-search-line"')
    end
  end

  describe 'liens de la home et du pied de page' do
    it 'branche les cartes, les boutons et le footer sur le catalogue et les pages statiques' do
      get root_path

      expect(response.body).to include('href="/demarches?target-users=particuliers"')
      expect(response.body).to include('href="/demarches?target-users=entreprises"')
      expect(response.body).to include('href="/demarches?target-users=associations"')
      expect(response.body).to include('href="/about"')
      expect(response.body).to include('href="/doctrine-referencement-cas-usages"')
      expect(response.body).to include('href="/doctrine-referencement-solutions"')
      expect(response.body).to include('href="/contact/contenu"')
      expect(response.body).not_to include('demarches-simplifiees.fr')
      expect(response.body).to include('Explorer le catalogue des démarches')
      expect(response.body).to include('href="/sitemap">Plan du site</a>')
      expect(response.body).to include('href="/terms">Conditions générales')
      expect(response.body).to include('href="https://www.data.gouv.fr/fr/suivi/">Politique de confidentialité</a>')
      expect(response.body).to include('href="/accessibility">Accessibilité : non conforme</a>')
      expect(response.body).not_to include('<a href="#" class="fr-btn')
    end
  end

  describe 'pages statiques' do
    { '/doctrine-referencement-cas-usages' => "Doctrine de référencement des cas d'usages",
      '/doctrine-referencement-solutions' => 'Doctrine de référencement des solutions',
      '/niveaux-simplification' => ['Guide pour la simplification', 'Niveaux de simplification'],
      '/terms' => "Conditions générales d'utilisation",
      '/accessibility' => 'Accessibilité',
      '/contact' => 'Nous contacter' }.each do |chemin, (titre, h1)|
      it "rend #{chemin} avec son titre" do
        get chemin

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("<h1>#{h1 || titre}</h1>")
        expect(response.body).to include("#{ERB::Util.html_escape(titre)} | Simplifions.data.gouv.fr</title>")
        expect(response.parsed_body.css('.fr-breadcrumb__list li').map { |etape| etape.text.strip }).to eq(['Accueil', titre])
        expect(response.body).not_to include('href="/cas-d-usages"')
      end
    end

    it 'répare les sommaires copiés : ancres, ids uniques, nav étiquetée' do
      get '/doctrine-referencement-solutions'
      expect(response.body).to include('href="#referencement-solution"')
      expect(response.body).to include('id="referencement-solution"')
      expect(response.body).to include('id="fr-summary-title"')
      expect(response.body).to include('href="#regles-de-referencement"')
      expect(response.body).not_to include('Contenu rédigé par')

      get '/niveaux-simplification'
      expect(response.body.scan(/id="summary-link-\d+"/).uniq.size).to eq(3)
    end

    it 'espace les titres de section sous le sommaire comme l’ancien site' do
      %w[/doctrine-referencement-cas-usages /doctrine-referencement-solutions /niveaux-simplification].each do |chemin|
        get chemin
        expect(response.body).to include('<h2 id="', 'class="fr-h2 fr-mt-5w fr-mb-0"')
        expect(response.body).not_to include('fr-my-0w')
      end
    end

    it 'mène l’about vers la demande de modification de contenu' do
      get about_path
      expect(response.body).to include('<a href="/contact/contenu">proposer des modifications</a>')
    end

    it 'relie les doctrines et l’about au catalogue et aux niveaux' do
      get '/doctrine-referencement-cas-usages'
      expect(response.body).to include('href="/demarches"')

      get about_path
      expect(response.body).to include('href="/niveaux-simplification"')
      expect(response.body).to include('href="/demarches"')
    end
  end

  describe 'GET /sitemap' do
    def sous_liens(entree)
      response.parsed_body.css('main li').find { |li| li.at_css('> h2')&.text&.strip == entree }
        .css('ul a').map { |lien| [lien['href'], lien.text.strip] }
    end

    it 'liste les huit entrées du site actuel, sans « Jeux de données »' do
      get '/sitemap'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<h1>Plan du site</h1>')
      expect(response.body).to include('Plan du site | Simplifions.data.gouv.fr</title>')
      entrees = response.body.scan(%r{<h2><a href="([^"]+)">([^<]+)</a></h2>})
        .map { |chemin, nom| [chemin, CGI.unescapeHTML(nom)] }
      expect(entrees).to eq([['/', 'Accueil'], ['/demarches', "Cas d'usages"], ['/articles', 'Articles'],
                             ['/solutions', 'Solutions'], ['/about', 'À propos'], ['/contact', 'Nous contacter'],
                             ['/terms', "Conditions générales d'utilisation"], ['/accessibility', 'Accessibilité']])
      expect(response.body).not_to include('Jeux de données')
    end

    it 'liste sous leur entrée les cas d’usages, solutions et articles visibles, par ordre alphabétique' do
      Demarche.create!(nom: 'Transport scolaire', slug: 'transport', visible: true)
      Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true)
      Demarche.create!(nom: 'Brouillon', slug: 'brouillon')
      Solution.create!(nom: 'Babily', slug: 'babily', visible: true, categorie: 'brique_logicielle')
      Solution.create!(nom: 'API Quotient familial', categorie: 'api', visible: true, uid_datagouv: 'qf')

      get '/sitemap'

      expect(sous_liens("Cas d'usages")).to eq([['/demarches/cantine', 'Cantine'], ['/demarches/transport', 'Transport scolaire']])
      expect(sous_liens('Solutions')).to eq([['/solutions/babily', 'Babily']])
      expect(sous_liens('Articles')).to eq(Article.all.sort_by(&:h1).map { |article| ["/articles/#{article.slug}", article.h1] })
      expect(sous_liens('À propos')).to eq([['/doctrine-referencement-cas-usages', "Doctrine de référencement des cas d'usages"],
                                            ['/doctrine-referencement-solutions', 'Doctrine de référencement des solutions'],
                                            ['/niveaux-simplification', 'Guide pour la simplification']])
      expect(response.body).not_to include('brouillon')
      expect(response.body).not_to include('Quotient')
    end
  end

  describe 'GET /about' do
    it 'renders the about page mirroring simplifions.data.gouv.fr/about' do
      get about_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('À propos')
      expect(response.body).to include('Le site recense :')
      expect(response.body).to include('fr-breadcrumb')
    end
  end
end
