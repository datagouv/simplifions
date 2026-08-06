require 'rails_helper'
require 'rake'

RSpec.describe 'rake grist:import' do
  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?('grist:import')
    Rake::Task['grist:import'].reenable
    stub_grist_tables
  end

  it 'imports the catalogue and prints the report' do
    expect { Rake::Task['grist:import'].invoke }
      .to output(/quarantaine : API_et_datasets_integres:496.*2 démarches/m).to_stdout
  end

  it 'exits with an error status when the import fails' do
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Solutions/records").to_return(status: 500)
    expect { Rake::Task['grist:import'].invoke }
      .to raise_error(SystemExit).and output(/échoué/i).to_stdout
  end
end
