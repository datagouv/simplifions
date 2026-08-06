require 'rails_helper'

RSpec.describe Grist::FetchTables do
  subject(:result) { described_class.call }

  context 'when the Grist API answers' do
    before { stub_grist_tables }

    it { is_expected.to be_a_success }

    it 'exposes every table records keyed by table name' do
      expect(result.tables.keys).to match_array(described_class::TABLES)
      expect(result.tables['Solutions']).to include(
        hash_including('id' => 1, 'fields' => hash_including('Nom' => 'Bouquet API Particulier'))
      )
    end
  end

  context 'when the Grist API fails' do
    before do
      stub_grist_tables
      stub_request(:get, "#{described_class::DOC_URL}/tables/Solutions/records").to_return(status: 500)
    end

    it { is_expected.to be_a_failure }

    it 'reports the failing table' do
      expect(result.errors.join).to include('Solutions')
    end
  end
end
