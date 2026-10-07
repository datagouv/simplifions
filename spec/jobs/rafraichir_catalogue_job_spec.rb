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

  it 'signe ses changements « Import Grist » puis « data.gouv », sans version quand rien ne change' do
    described_class.perform_now
    solution = Solution.sur_datagouv.first

    expect(solution.versions.map(&:whodunnit)).to eq(['Import Grist', 'data.gouv'])
    expect(solution.versions.last.changeset).to include('datagouv_titre' => [nil, 'Titre data.gouv'])
    expect { described_class.perform_now }.not_to change(PaperTrail::Version, :count)
  end

  it "laisse sortir l'échec de l'import Grist sans appeler data.gouv" do
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Solutions/records").to_return(status: 500)

    expect { described_class.perform_now }.to raise_error(RuntimeError, /Solutions/)
    expect(a_request(:get, %r{data\.gouv\.fr/api/})).not_to have_been_made
  end

  describe 'un seul passage à la fois' do
    around do |example|
      adaptateur = described_class.queue_adapter
      described_class.queue_adapter = :solid_queue
      example.run
    ensure
      described_class.queue_adapter = adaptateur
    end

    it 'écarte une demande arrivée pendant un passage en cours' do
      2.times { described_class.perform_later }

      expect(SolidQueue::Job.where(class_name: described_class.name).count).to eq(1)
    end
  end
end
