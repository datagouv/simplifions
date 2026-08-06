require 'rails_helper'

RSpec.describe Grist::AttachImages do
  subject(:result) { call_interactor }

  let(:solution) { Solution.create!(nom: 'Bouquet API Particulier', grist_id: 'Solutions:1') }
  let(:tables) do
    { 'Solutions' => [{ 'id' => 1, 'fields' => { 'Nom' => 'Bouquet API Particulier', 'Image' => ['L', 7] } }] }
  end
  let(:download_url) { "#{Grist::FetchTables::DOC_URL}/attachments/7/download" }

  def call_interactor
    described_class.call(tables:, index: { 'Solutions:1' => solution },
      report: { quarantine: [], notes: [] })
  end

  before do
    stub_request(:get, download_url).to_return(
      status: 200, body: 'PNGBYTES',
      headers: { 'Content-Type' => 'image/png', 'Content-Disposition' => 'attachment; filename="logo.png"' }
    )
  end

  it { is_expected.to be_a_success }

  it 'copies the Grist attachment into Active Storage' do
    expect { result }.to change { solution.reload.image.attached? }.from(false).to(true)
    expect(solution.image.filename.to_s).to eq('logo.png')
  end

  it 'does not download again when an image is already attached' do
    call_interactor
    call_interactor
    expect(a_request(:get, download_url)).to have_been_made.once
  end

  it 'quarantines download failures without crashing' do
    stub_request(:get, download_url).to_return(status: 404)
    expect(result.report[:quarantine].join).to include('Solutions:1')
    expect(solution.reload.image).not_to be_attached
  end
end
