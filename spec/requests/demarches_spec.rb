require 'rails_helper'

RSpec.describe 'Demarches' do
  describe 'GET /demarches/:slug' do
    it 'rend la démarche visible' do
      Demarche.create!(nom: 'Tarification cantine scolaire à 1€', slug: 'tarification-cantine-scolaire-a-1eur',
        visible: true)

      get demarche_path('tarification-cantine-scolaire-a-1eur')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tarification cantine scolaire à 1€')
    end

    it 'renvoie 404 pour une démarche non visible' do
      Demarche.create!(nom: 'Brouillon', slug: 'brouillon', visible: false)

      get demarche_path('brouillon')

      expect(response).to have_http_status(:not_found)
    end

    it 'renvoie 404 pour un slug inconnu' do
      get demarche_path('nexiste-pas')

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'anciennes URLs /cas-d-usages' do
    it 'redirige en 301 vers /demarches/:slug' do
      get '/cas-d-usages/tarification-cantine-scolaire-a-1eur'

      expect(response).to redirect_to('/demarches/tarification-cantine-scolaire-a-1eur')
      expect(response).to have_http_status(:moved_permanently)
    end

    it 'redirige l’ancien slug publié de suivi-des-tiers-aides vers le nouveau' do
      get '/cas-d-usages/aides-publiques-personnes-morales-et-entreprises-individuelles-suivi-des-tiers-aides'

      expect(response).to redirect_to('/demarches/aides-publiques-entreprises-et-associations-suivi-des-tiers-aides')
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
