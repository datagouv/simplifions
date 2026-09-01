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

  describe 'explorateur de la page d’accueil' do
    it 'envoie vers /demarches avec les facettes du site' do
      Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')

      get root_path

      expect(response.body).to include('<form class="explorateur" action="/demarches" accept-charset="UTF-8" method="get">')
      expect(response.body).to include('<select class="fr-select" id="select-target-users" name="target-users">')
      expect(response.body).to include('<option value="">particuliers, entreprises, associations</option>')
      expect(response.body).to include('<option value="particuliers">Particuliers</option>')
      expect(response.body).to include('<select class="fr-select" id="select-fournisseurs" name="fournisseurs-de-service">')
      expect(response.body).to include('<option value="communes">Communes et groupements de communes</option>')
      expect(response.body).to include('<button type="submit" class="fr-btn fr-btn--icon-right fr-icon-search-line">')
      expect(response.body).not_to include('href="#" class="fr-btn fr-btn--icon-right fr-icon-search-line"')
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
