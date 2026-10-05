require 'rails_helper'

RSpec.describe TypeActeur do
  describe '#slugs=' do
    it 'ne garde que les filtres du site, sans la case vide du formulaire ni les valeurs inconnues' do
      expect(described_class.new(slugs: ['', 'regions', 'inconnu', 'communes']).slugs).to eq(%w[regions communes])
    end
  end

  describe '#regroupements' do
    it 'nomme ses filtres avec les libellés du site' do
      expect(described_class.new(slugs: %w[etat regions]).regroupements).to eq(%w[État Régions])
    end

    it 'ignore un slug enregistré avant la liste fermée' do
      fournisseur = described_class.new
      fournisseur[:slugs] = %w[acteurs-sante etat]
      expect(fournisseur.regroupements).to eq(%w[État])
    end
  end
end
