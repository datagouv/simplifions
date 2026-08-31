require 'rails_helper'

RSpec.describe 'Solutions' do
  describe 'GET /solutions/:slug' do
    it 'rend la solution visible' do
      Solution.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle',
        slug: 'bouquet-api-particulier', visible: true)

      get solution_path('bouquet-api-particulier')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Bouquet API Particulier')
    end

    it 'renvoie 404 pour une solution non visible' do
      Solution.create!(nom: 'Brouillon', categorie: 'brique_logicielle', slug: 'brouillon', visible: false)

      get solution_path('brouillon')

      expect(response).to have_http_status(:not_found)
    end

    it 'renvoie 404 pour un slug inconnu' do
      get solution_path('nexiste-pas')

      expect(response).to have_http_status(:not_found)
    end

    it 'renvoie 404 pour une API, qui n’a pas de page' do
      Solution.create!(nom: 'API Quotient familial', categorie: 'api', visible: true)

      get solution_path('api-quotient-familial')

      expect(response).to have_http_status(:not_found)
    end
  end
end
