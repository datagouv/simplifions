require 'rails_helper'

RSpec.shared_examples 'un CRUD brut' do |modele, chemin|
  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }
  let!(:ligne) { modele.create!(attributs) }

  it 'exige la connexion' do
    get "/admin/#{chemin}"
    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'liste les lignes avec un lien de modification' do
    sign_in admin
    get "/admin/#{chemin}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<td>#{ligne.id}</td>")
    expect(response.body).to include("href=\"/admin/#{chemin}/#{ligne.id}/edit\"")
  end
end

RSpec.describe 'Administration' do
  it_behaves_like 'un CRUD brut', Demarche, 'demarches' do
    let(:attributs) { { nom: 'Aides publiques' } }
  end

  it_behaves_like 'un CRUD brut', Solution, 'solutions' do
    let(:attributs) { { nom: 'Bouquet API Particulier' } }
  end

  it_behaves_like 'un CRUD brut', Recommandation, 'recommandations' do
    let(:attributs) { { demarche: Demarche.create!(nom: 'Aides'), solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: 'niveau_1' } }
  end

  it_behaves_like 'un CRUD brut', Integration, 'integrations' do
    let(:attributs) do
      { integratrice: Solution.create!(nom: 'Bouquet'), integree: Solution.create!(nom: 'API QF'), type_integration: 'expose' }
    end
  end

  it_behaves_like 'un CRUD brut', Organisation, 'organisations' do
    let(:attributs) { { nom: 'DINUM' } }
  end

  it_behaves_like 'un CRUD brut', TypeActeur, 'types_acteurs' do
    let(:attributs) { { nom: 'Communes' } }
  end

  it_behaves_like 'un CRUD brut', Vocabulaire, 'vocabulaires' do
    let(:attributs) { { nom: 'Particuliers', categorie: 'usager' } }
  end

  describe 'GET /admin' do
    it 'mène à chaque table du catalogue' do
      sign_in Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide')
      get admin_root_path
      %w[demarches solutions recommandations integrations organisations types_acteurs vocabulaires].each do |chemin|
        expect(response.body).to include("href=\"/admin/#{chemin}\"")
      end
    end
  end
end
