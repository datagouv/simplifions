require 'rails_helper'

RSpec.describe Vocabulaire do
  describe 'slug' do
    def erreurs(slug) = described_class.new(nom: 'Particuliers', categorie: 'usager', slug:).tap(&:validate).errors.full_messages

    it 'exige un slug fait de minuscules sans accent, de chiffres et de tirets' do
      expect(erreurs('particuliers-2')).to be_empty
      expect(erreurs(' ')).to eq(['Slug doit être rempli'])
      expect(erreurs('Particuliers')).to eq(['Slug ne doit contenir que des minuscules sans accent, des chiffres et des tirets'])
    end
  end

  describe '#libelle' do
    it 'affiche les libellés du site actuel pour les types de simplification, le nom sinon' do
      expect(described_class.new(nom: '💠💠 DLNUF', slug: 'dlnuf').libelle).to eq('Dites-le nous une fois')
      expect(described_class.new(nom: '💠 Accès facile', slug: 'acces-facile').libelle).to eq('Accès facile')
      expect(described_class.new(nom: 'Particuliers', slug: 'particuliers').libelle).to eq('Particuliers')
    end
  end
end
