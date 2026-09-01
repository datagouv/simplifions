require 'rails_helper'

RSpec.describe Vocabulaire do
  describe '#libelle' do
    it 'affiche les libellés du site actuel pour les types de simplification, le nom sinon' do
      expect(described_class.new(nom: '💠💠 DLNUF', slug: 'dlnuf').libelle).to eq('Dites-le nous une fois')
      expect(described_class.new(nom: '💠 Accès facile', slug: 'acces-facile').libelle).to eq('Accès facile')
      expect(described_class.new(nom: 'Particuliers', slug: 'particuliers').libelle).to eq('Particuliers')
    end
  end
end
