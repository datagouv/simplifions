require 'rails_helper'

RSpec.describe Integration do
  let(:bouquet) { Solution.create!(nom: 'Bouquet') }
  let(:api) { Solution.create!(nom: 'API') }

  describe '.en_production' do
    it 'keeps only integrations with the production status' do
      en_prod = described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme',
        statut: '✅ en production')
      described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme',
        statut: '💡 en prospection')

      expect(described_class.en_production).to contain_exactly(en_prod)
    end
  end

  describe '.pour_demarche' do
    it 'keeps only integrations scoped to the given demarche' do
      cantine = Demarche.create!(nom: 'Cantine à 1€')
      autre = Demarche.create!(nom: 'Autre démarche')
      scopee = described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme',
        demarches: [cantine])
      described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme', demarches: [autre])

      expect(described_class.pour_demarche(cantine)).to contain_exactly(scopee)
    end
  end

  it 'rejects unknown integration types' do
    expect {
      described_class.new(type_integration: 'transporte')
    }.to raise_error(ArgumentError)
  end
end
