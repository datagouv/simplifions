require 'rails_helper'

RSpec.describe 'Sentry' do
  subject(:config) { Sentry.configuration }

  it "n'envoie rien sans SENTRY_DSN" do
    expect(config.dsn).to be_nil
    expect(config.sending_allowed?).to be(false)
  end

  it 'ne transmet ni PII ni traces de performance' do
    expect(config.send_default_pii).to be(false)
    expect(config.traces_sample_rate).to be_nil
    expect(config.traces_sampler).to be_nil
  end

  it 'nomme l’environnement Rails' do
    expect(config.environment).to eq('test')
  end
end
