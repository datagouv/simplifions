require 'rails_helper'

RSpec.describe 'Pages d’erreur' do
  around do |exemple|
    config = Rails.application.env_config
    precedente = config.slice('action_dispatch.show_exceptions', 'action_dispatch.show_detailed_exceptions')
    config.merge!('action_dispatch.show_exceptions' => :all, 'action_dispatch.show_detailed_exceptions' => false)
    exemple.run
  ensure
    config.merge!(precedente)
  end

  it 'affiche la page DSFR « Page non trouvée » pour une adresse inconnue' do
    get '/page-inexistante'

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.at('h1').text).to eq('Page non trouvée')
    expect(response.body).to include('data-matomo-erreur="404"')
  end

  it 'renvoie la même page pour un cas d’usage inconnu' do
    get '/demarches/slug-inconnu'

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.at('h1').text).to eq('Page non trouvée')
  end

  it 'garde la page HTML pour une adresse inconnue en .json' do
    get '/page-inexistante.json'

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.at('h1').text).to eq('Page non trouvée')
  end

  it 'garde la page statique pour une erreur serveur' do
    allow(Demarche).to receive(:visibles).and_raise('panne')

    get demarches_path

    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to eq(Rails.public_path.join('500.html').read)
  end
end
