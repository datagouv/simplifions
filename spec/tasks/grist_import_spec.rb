require 'rails_helper'
require 'rake'

RSpec.describe 'rake grist:import' do
  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?('grist:import')
    Rake::Task['grist:import'].reenable
    Rake::Task['datagouv:import'].reenable
    stub_grist_tables
    stub_request(:get, %r{data\.gouv\.fr/api/}).to_return(status: 404)
  end

  it 'imports the catalogue, prints the report, then refreshes the data.gouv metadata' do
    expect { Rake::Task['grist:import'].invoke }
      .to output(/quarantaine : API_et_datasets_integres:496.*2 démarches.*rafraîchie/m).to_stdout
    expect(a_request(:get, %r{data\.gouv\.fr/api/})).to have_been_made.at_least_once
  end

  it 'signe les changements de l’import « Import Grist »' do
    expect { Rake::Task['grist:import'].invoke }.to output.to_stdout
    expect(PaperTrail::Version.distinct.pluck(:whodunnit)).to eq(['Import Grist'])
  end

  it 'raises the import error so Sentry reports it' do
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Solutions/records").to_return(status: 500)
    expect { Rake::Task['grist:import'].invoke }.to raise_error(RuntimeError, 'Grist Solutions: HTTP 500')
    expect(a_request(:get, %r{data\.gouv\.fr/api/})).not_to have_been_made
  end
end
