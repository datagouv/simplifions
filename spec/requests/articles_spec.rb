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
