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

  describe '.visibles' do
    it 'returns only visible solutions' do
      visible = described_class.create!(nom: 'Publiée', visible: true)
      described_class.create!(nom: 'Brouillon', visible: false)

      expect(described_class.visibles).to contain_exactly(visible)
    end
  end
end
