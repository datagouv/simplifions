require 'rails_helper'

RSpec.describe 'Administration' do
  describe 'GET /admin' do
    it 'renvoie vers la page de connexion sans admin connecté' do
      get admin_root_path
      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end
