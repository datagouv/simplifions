require 'rails_helper'

RSpec.describe 'Administration' do
  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }

  describe 'GET /admin' do
    it 'renvoie vers la page de connexion sans admin connecté' do
      get admin_root_path
      expect(response).to redirect_to(new_admin_session_path)
    end

    it 'affiche le tableau de bord une fois connecté' do
      sign_in admin
      get admin_root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<h1>Administration</h1>')
    end
  end

  describe 'POST /admin/connexion' do
    it 'ouvre la session et mène au tableau de bord' do
      post admin_session_path, params: { admin: { email: admin.email, password: 'mot-de-passe-solide' } }
      expect(response).to redirect_to(admin_root_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end
end
