require 'rails_helper'

RSpec.describe 'LogStasher configuration' do
  subject(:yml) { YAML.safe_load_file(Rails.root.join('config/logstasher.yml')) }

  it "ne règle que le développement et les tests : very_ansible règle les serveurs, une clé de tête s'y appliquerait" do
    expect(yml.keys).to eq(%w[development test])
  end

  it "écrit le journal JSON en développement, au niveau info : celui de la gem (WARN) écarte les lignes d'information" do
    expect(yml['development']).to include('enabled' => true, 'log_level' => 'info')
  end

  it "laisse éteint l'abonné aux jobs de la gem : il écrit le message brut des exceptions" do
    expect(yml.dig('development', 'job_enabled')).to be(false)
  end

  it "n'écrit pas le journal JSON pendant les tests" do
    expect(Rails.application.config.logstasher.enabled).to be(false)
  end

  it 'ne règle jamais log_controller_parameters : toute valeur, false comprise, journalise les paramètres' do
    expect(Rails.root.join('config/logstasher.yml').read).not_to include('log_controller_parameters')
  end
end
