require 'rails_helper'

RSpec.describe 'Matomo' do
  before { allow(ENV).to receive(:[]).and_call_original }

  it 'ne charge rien sans MATOMO_SITE_ID' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return(nil)

    get root_path

    expect(response.body).not_to include('stats.data.gouv.fr')
  end

  it 'charge le tag standard avec le site id fourni' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include('https://stats.data.gouv.fr/')
    expect(response.body).to include("_paq.push(['setTrackerUrl', u + 'matomo.php'])")
    expect(response.body).to include("_paq.push(['setSiteId', '311'])")
  end

  it 'mesure chaque page affichée par Turbo, pas seulement le premier chargement' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    script = response.parsed_body.css('head script').map(&:text).find { |texte| texte.include?('matomo.js') }
    expect(script).to include("addEventListener('turbo:load'")
  end
end
