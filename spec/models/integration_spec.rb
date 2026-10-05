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

  describe 'statut' do
    let(:integration) { described_class.new(integratrice: bouquet, integree: api, type_integration: 'consomme') }

    it 'accepte les statuts Grist et le vide, refuse une saisie hors liste' do
      expect(described_class::STATUTS).to include('🚧 Intéressé si évolution')
      [nil, '', *described_class::STATUTS].each do |statut|
        expect(integration.tap { it.statut = statut }).to be_valid
      end
      integration.statut = 'en production'
      expect(integration).not_to be_valid
      expect(integration.errors.full_messages).to eq(['Statut doit être choisi dans la liste'])
    end
  end

  it 'refuse qu’une solution s’intègre elle-même' do
    integration = described_class.new(integratrice: bouquet, integree: bouquet, type_integration: 'consomme')
    expect(integration).not_to be_valid
    expect(integration.errors.full_messages).to eq(['Une solution ne peut pas s’intégrer elle-même'])
  end

  describe '#libelle' do
    it 'nomme la paire et le sens de l’intégration' do
      integration = described_class.new(integratrice: Solution.new(nom: 'Bouquet'), integree: Solution.new(nom: 'API QF'), type_integration: 'consomme')
      expect(integration.libelle).to eq('Bouquet → API QF (consomme)')
    end
  end
end
