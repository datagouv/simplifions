require 'rails_helper'

RSpec.describe 'Navigateurs anciens' do
  let(:firefox_115) { { 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:115.0) Gecko/20100101 Firefox/115.0' } }

  it 'servent la page d’accueil' do
    get root_path, headers: firefox_115
    expect(response).to have_http_status(:ok)
  end

  it 'servent la page d’un cas d’usage' do
    Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', visible: true)
    get demarche_path('cantine'), headers: firefox_115
    expect(response).to have_http_status(:ok)
  end

  it 'servent la page de connexion de l’administration' do
    get new_admin_session_path, headers: firefox_115
    expect(response).to have_http_status(:ok)
  end
end
