RSpec.describe 'Pages' do
  describe 'GET /' do
    it 'renders the homepage with the DSFR layout' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Bienvenue sur Simplifions')
      expect(response.body).to include('fr-header')
      expect(response.body).to include('fr-footer')
    end
  end
end
