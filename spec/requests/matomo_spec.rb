require 'rails_helper'

RSpec.describe 'Matomo' do
  it 'ne charge rien sans MATOMO_SITE_ID' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return(nil)

    get root_path

    expect(response.body).not_to include('stats.data.gouv.fr')
  end

  it 'charge le tag standard avec le site id fourni' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include('https://stats.data.gouv.fr/')
    expect(response.body).to include("_paq.push(['setTrackerUrl', u + 'matomo.php'])")
    expect(response.body).to include("_paq.push(['setSiteId', '311'])")
  end
end
