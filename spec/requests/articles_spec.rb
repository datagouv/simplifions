require 'rails_helper'

RSpec.describe 'Articles' do
  describe 'GET /articles' do
    it 'liste les six articles' do
      get articles_path
      expect(response).to have_http_status(:ok)
      Article::ALL.each do |article|
        expect(response.body).to include(ERB::Util.html_escape(article.h1))
      end
    end

    it 'grise, comme un bouton désactivé, les mots-clefs sans article' do
      get articles_path
      expect(response.body).to match(%r{<button[^>]*class="fr-tag"[^>]*disabled[^>]*>Jeux de données \(0\)</button>})
    end

    it 'prépare pour Matomo le choix et le retrait d’un mot-clef, et l’ouverture d’un article' do
      get articles_path(keywords: 'Guide de base')
      page = Capybara.string(response.body)

      expect(page.find('.fr-container[data-matomo-zone]')['data-matomo-zone']).to eq('Articles › Liste')
      retrait = page.find('a.fr-tag[aria-pressed="true"]')
      expect([retrait['data-matomo-action'], retrait['data-matomo-nom']]).to eq(['Retirer un mot-clé', 'Guide de base'])
      expect(page.first('a.fr-tag[aria-pressed="false"]')['data-matomo-action']).to eq('Filtrer par mot-clé')
      carte = page.find_link('Guide de base pour les petites collectivités')
      expect([carte['data-matomo-action'], carte['data-matomo-nom']])
        .to eq(['Ouvrir un article', 'Guide de base pour les petites collectivités'])
    end

    it 'filtre par mot-clef' do
      get articles_path(keywords: 'Guide de base')
      expect(response.body).to include('Guide de base pour les petites collectivités')
      expect(response.body).not_to include('Les API FranceConnectées</a>')
    end
  end

  describe 'GET /articles/:slug' do
    Article::ALL.each do |article|
      it "rend #{article.slug}" do
        get article_path(article.slug)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(article.h1))
      end
    end

    it 'liste dans l’article FranceConnectées les API visibles marquées FranceConnectée, dans l’ordre Grist' do
      Solution.create!(nom: 'API Impôt particulier', categorie: 'api', visible: true, france_connectee: true,
        uid_datagouv: 'impot', datagouv_titre: 'API Impôt particulier (data.gouv)', datagouv_acces: 'restricted')
      Solution.create!(nom: 'API Quotient familial', categorie: 'api', visible: true, france_connectee: true,
        uid_datagouv: 'qf', datagouv_organisation: 'DINUM', datagouv_logo: 'https://avatars.test/dinum-100.png')
      Solution.create!(nom: 'API brouillon', categorie: 'api', france_connectee: true, uid_datagouv: 'brouillon')
      Solution.create!(nom: 'API sans FranceConnect', categorie: 'api', visible: true, uid_datagouv: 'sans')
      Solution.create!(nom: 'Base FC', categorie: 'base_de_donnees', visible: true, france_connectee: true, uid_datagouv: 'base')

      get article_path('apis-franceconnectees')

      expect(response.body).to match(/API en accès restreint.*API Impôt particulier \(data.gouv\).*avatars.test.*API Quotient familial.*DINUM/m)
      expect(response.body).to include('https://www.data.gouv.fr/fr/dataservices/impot')
      expect(response.body).not_to include('API brouillon')
      expect(response.body).not_to include('API sans FranceConnect')
      expect(response.body).not_to include('Base FC')
    end

    it 'tire les cartes citées de la fiche en base : nom et opérateur' do
      Solution.create!(nom: 'FranceConnect v2', slug: 'franceconnect-2', visible: true,
        organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])

      get article_path('apis-franceconnectees')

      cartes = response.parsed_body.css('.spotlight')
      expect(cartes.css('a[href="/solutions/franceconnect-2"]').text).to eq('FranceConnect v2')
      expect(cartes.css('.fr-badge').text.squish).to eq('Solution publique | DINUM')
    end

    it 'rend l’article sans la carte d’une solution cachée ou disparue' do
      Solution.create!(nom: 'FranceConnect', slug: 'franceconnect-2')

      get article_path('apis-franceconnectees')

      expect(response).to have_http_status(:ok)
      article = response.parsed_body.at_css('main').to_html
      expect(article).not_to include('/solutions/franceconnect-2')
      expect(article).not_to include('/solutions/bouquet-api-particulier')
    end

    it 'signale à Sentry une fiche citée introuvable, mais pas une fiche masquée' do
      Solution.create!(nom: 'FranceConnect', slug: 'franceconnect-2')
      allow(Sentry).to receive(:capture_message)

      get article_path('apis-franceconnectees')

      expect(Sentry).to have_received(:capture_message).at_least(:once).with(/solution.*bouquet-api-particulier/)
      expect(Sentry).not_to have_received(:capture_message).with(/franceconnect-2/)
    end

    it 'signale à Sentry une démarche citée introuvable' do
      allow(Sentry).to receive(:capture_message)

      get article_path('guide-base-petites-collectivites')

      expect(Sentry).to have_received(:capture_message)
        .at_least(:once).with(/démarche.*marches-publics-depot-et-instruction-des-candidatures/)
    end

    it 'fait défiler le bloc « Sont mentionnés » avec Précédent / Suivant' do
      Solution.create!(nom: 'Bouquet API Entreprise', slug: 'bouquet-api-entreprise', visible: true)

      get article_path('qu-est-ce-qu-une-api')
      carrousel = response.parsed_body.css('[data-controller="carousel"]')
      expect(carrousel.css('.carousel-track')).to be_present
      expect(carrousel.css('[data-carousel-target="nav"].fr-hidden')).to be_present
      expect(carrousel.css('button').map(&:text).map(&:strip)).to eq(%w[Précédent Suivant])
    end

    it 'prépare pour Matomo le sommaire, les liens du texte, « Lire aussi » et les mentions de l’article' do
      Solution.create!(nom: 'Bouquet API Entreprise', slug: 'bouquet-api-entreprise', visible: true)

      get article_path('qu-est-ce-qu-une-api')
      page = Capybara.string(response.body)
      article = page.find('.article-page')

      expect([article['data-matomo-zone'], article['data-matomo-contexte']])
        .to eq(['Article › Contenu', Article.find('qu-est-ce-qu-une-api').h1])
      sommaire = page.find('nav.article-toc')
      expect(sommaire['data-matomo-zone']).to eq('Article › Sommaire')
      expect(sommaire.find('button')['data-matomo-action']).to eq('Ouvrir le sommaire')
      expect(sommaire.all('a').pluck('data-matomo-action').uniq).to eq(['Aller à une section'])
      expect(page.find('.article-content')['data-matomo-liens']).to eq("Ouvrir un lien de l'article")
      expect(page.find('.fr-callout a', text: 'interlocuteurs', match: :first)['data-matomo-action']).to eq('Lire aussi')
      mentions = page.find('[data-controller="carousel"]')
      expect(mentions['data-matomo-zone']).to eq('Article › Mentions')
      expect(mentions.all('button').pluck('data-matomo-action'))
        .to eq(['Voir la mention précédente', 'Voir la mention suivante'])
    end

    it 'réserve au démonstrateur Sirene une annonce vide au chargement, pour le lecteur d’écran' do
      get article_path('qu-est-ce-qu-une-api')
      annonce = response.parsed_body.at_css('[data-controller="sirene-demo"] [role=status]')
      expect(annonce.text).to be_empty
    end

    it 'rend les tuiles des encarts comme le site actuel : sans tag de catégorie, description ou audience selon l’article' do
      particuliers = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      communes = TypeActeur.create!(nom: 'Communes')
      %w[franceconnect-2 bouquet-api-particulier formulaire-de-collecte-du-quotient-familial].each do |slug|
        Solution.create!(nom: slug, slug:, visible: true, description_courte: 'Chapo de la fiche',
          vocabulaires: [particuliers], types_acteurs: [communes])
      end
      Demarche.create!(nom: 'Marchés publics', slug: 'marches-publics-depot-et-instruction-des-candidatures', visible: true,
        vocabulaires: [particuliers], types_acteurs: [communes])

      get article_path('apis-franceconnectees')
      spotlights = response.parsed_body.css('.spotlight')
      expect(spotlights.text).to include('FranceConnect est une solution d’identification')
      expect(spotlights.text).to include('API distribuant les données des particuliers')
      expect(spotlights.text).not_to include('Pour simplifier les démarches')
      expect(response.body).not_to include('Chapo de la fiche')

      get article_path('guide-base-petites-collectivites')
      page = response.parsed_body
      marches = page.css('.spotlight').find { |spotlight| spotlight.text.include?('Marchés publics') }
      expect(marches.css('.fr-card__detail')).to be_empty
      expect(page.css('.carousel-track').text).to include('Pour simplifier les démarches')
      expect(page.css('.carousel-track').text).not_to include('À destination')
    end

    it 'renvoie vers la section « Parcours alternatifs » sans coquille' do
      get article_path('anticiper-le-parcours-usager-avant-d-integrer-vos-api')

      expect(response.body.scan("Plus d'informations sur parcours alternatifs").size).to eq(2)
      expect(response.body).not_to include('altenratifs')
    end

    it 'renvoie 404 pour un slug inconnu' do
      get article_path('nexiste-pas')
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'anciennes URLs à plat' do
    it 'redirige en 301 vers /articles/:slug' do
      get '/qu-est-ce-qu-une-api'
      expect(response).to redirect_to('/articles/qu-est-ce-qu-une-api')
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
