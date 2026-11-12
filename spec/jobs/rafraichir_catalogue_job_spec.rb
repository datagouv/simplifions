require 'rails_helper'

RSpec.describe RafraichirCatalogueJob do
  let!(:solution) { Solution.create!(nom: 'API Particulier', uid_datagouv: 'api-particulier') }

  before do
    stub_request(:get, %r{data\.gouv\.fr/api/})
      .to_return(status: 200, body: { title: 'Titre data.gouv', access_type: 'open' }.to_json)
  end

  it "garde une démarche créée dans l'admin, sans identifiant Grist" do
    demarche = Demarche.create!(nom: "Créée dans l'admin")

    described_class.perform_now

    expect(Demarche.exists?(demarche.id)).to be(true)
  end

  it "ne recopie plus le Grist : aucune requête n'y part" do
    described_class.perform_now

    expect(a_request(:get, /#{Regexp.escape(Grist::FetchTables::DOC_URL)}/o)).not_to have_been_made
  end

  it 'rafraîchit les métadonnées data.gouv, signées « data.gouv », sans version quand rien ne change' do
    described_class.perform_now

    expect(solution.reload.datagouv_titre).to eq('Titre data.gouv')
    expect(solution.versions.last).to have_attributes(whodunnit: 'data.gouv')
    expect { described_class.perform_now }.not_to change(PaperTrail::Version, :count)
  end

  describe 'journal JSON' do
    include_context 'with a captured LogStasher log'

    it 'écrit une ligne au début et une à la fin, avec les comptes du passage' do
      stub_request(:get, %r{data\.gouv\.fr/api/}).to_return(status: 500)

      described_class.perform_now

      expect(logstash_lines.pluck('event_type')).to eq(%w[rafraichissement_demarre rafraichissement_termine])
      expect(logstash_lines.last).to include('demarches' => Demarche.count, 'solutions' => 1, 'datagouv_en_echec' => 1)
    end

    it "écrit le type d'erreur d'un passage en échec, jamais son message" do
      allow(Solution).to receive(:rafraichir_datagouv).and_raise(ActiveRecord::ConnectionNotEstablished, 'base injoignable')

      expect { described_class.perform_now }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      expect(logstash_lines.last).to include('event_type' => 'rafraichissement_echoue',
        'error_class' => 'ActiveRecord::ConnectionNotEstablished')
      expect(logstash_io.string).not_to include('base injoignable')
    end
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
