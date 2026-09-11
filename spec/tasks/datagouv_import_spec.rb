require 'rails_helper'
require 'rake'

RSpec.describe 'rake datagouv:import' do
  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?('datagouv:import')
    Rake::Task['datagouv:import'].reenable
    Solution.create!(nom: 'API QF', categorie: 'api', uid_datagouv: 'qf')
    Solution.create!(nom: 'API perdue', categorie: 'api', uid_datagouv: 'perdue')
    Solution.create!(nom: 'Brique sans fiche', categorie: 'brique_logicielle')
    stub_request(:get, 'https://www.data.gouv.fr/api/1/dataservices/qf/')
      .to_return(status: 200, body: { title: 'API Quotient familial', access_type: 'open' }.to_json)
    stub_request(:get, 'https://www.data.gouv.fr/api/1/dataservices/perdue/').to_return(status: 404)
  end

  it 'rafraîchit les solutions référencées sur data.gouv et imprime les notes' do
    expect { Rake::Task['datagouv:import'].invoke }
      .to output(/note : perdue — HTTP 404.*1 solution\(s\) rafraîchie\(s\) sur 2/m).to_stdout
    expect(Solution.find_by(uid_datagouv: 'qf').datagouv_titre).to eq('API Quotient familial')
  end
end
