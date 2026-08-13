require 'rails_helper'

RSpec.describe Solution do
  describe '#exposees' do
    it 'returns only solutions integrated with type expose' do
      bouquet = described_class.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle')
      api_qf = described_class.create!(nom: 'API Quotient familial', categorie: 'api')
      france_connect = described_class.create!(nom: 'FranceConnect', categorie: 'api')
      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'expose')
      Integration.create!(integratrice: bouquet, integree: france_connect, type_integration: 'consomme')

      expect(bouquet.exposees).to contain_exactly(api_qf)
    end
  end

  describe '#fiche?' do
    it 'is false for the categories that come from APIs_et_datasets, true otherwise' do
      expect(described_class.new(categorie: 'api')).not_to be_fiche
      expect(described_class.new(categorie: 'base_de_donnees')).not_to be_fiche
      expect(described_class.new(categorie: 'brique_logicielle')).to be_fiche
      expect(described_class.new(categorie: nil)).to be_fiche
    end
  end

  describe '.visibles' do
    it 'returns only visible solutions' do
      visible = described_class.create!(nom: 'Publiée', visible: true)
      described_class.create!(nom: 'Brouillon', visible: false)

      expect(described_class.visibles).to contain_exactly(visible)
    end
  end
end
