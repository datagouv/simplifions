require 'rails_helper'

RSpec.describe RafraichirCatalogueJob do
  before do
    stub_grist_tables
    stub_request(:get, %r{data\.gouv\.fr/api/})
      .to_return(status: 200, body: { title: 'Titre data.gouv', access_type: 'open' }.to_json)
  end

  it 'importe le catalogue Grist puis rafraîchit les métadonnées data.gouv' do
    described_class.perform_now

    expect(Solution.sur_datagouv.pluck(:datagouv_titre).uniq).to eq(['Titre data.gouv'])
  end

  it "laisse sortir l'échec de l'import Grist sans appeler data.gouv" do
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Solutions/records").to_return(status: 500)

    expect { described_class.perform_now }.to raise_error(RuntimeError, /Solutions/)
    expect(a_request(:get, %r{data\.gouv\.fr/api/})).not_to have_been_made
  end
end
