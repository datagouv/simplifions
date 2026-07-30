RSpec.describe 'Pages' do
  describe 'GET /' do
    it 'renders the homepage mirroring simplifions.data.gouv.fr' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Le catalogue des données')
      expect(response.body).to include('Nouvelle version en construction')
      expect(response.body).to include('fr-header')
      expect(response.body).to include('fr-footer')
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
