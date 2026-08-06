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
