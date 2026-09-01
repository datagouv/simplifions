require 'rails_helper'

RSpec.describe Demarche do
  describe '.catalogue' do
    let(:particuliers) { Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager') }
    let(:dlnuf) { Vocabulaire.create!(nom: 'DLNUF', slug: 'dlnuf', categorie: 'type_simplification') }
    let(:logiciel) { Vocabulaire.create!(nom: 'Logiciel métier', slug: 'logiciel-metier', categorie: 'solution') }
    let(:communes) { TypeActeur.create!(nom: 'Communes', slugs: %w[communes tout-collectivites-territoires tout-acteurs-publics]) }
    let!(:cantine) do
      described_class.create!(nom: 'Tarification cantine', visible: true, cree_le: 1.day.ago, modifie_le: 3.days.ago,
        description_courte: 'Pour les démarches des familles', mots_clefs: %w[repas],
        vocabulaires: [particuliers, dlnuf, logiciel], types_acteurs: [communes])
    end
    let!(:marches) do
      described_class.create!(nom: 'Marchés publics', visible: true, cree_le: 2.days.ago, modifie_le: 1.day.ago,
        description_courte: 'Justificatifs des entreprises', types_acteurs: [TypeActeur.create!(nom: 'État', slugs: %w[etat])])
    end

    before { described_class.create!(nom: 'Brouillon entreprise', visible: false) }

    it 'liste les démarches visibles dans l’ordre Grist' do
      expect(described_class.catalogue({})).to eq([cantine, marches])
    end

    it 'filtre par usager, type de simplification, catégorie de solution et type d’acteur (tous ses slugs)' do
      expect(described_class.catalogue('target-users' => 'particuliers')).to eq([cantine])
      expect(described_class.catalogue('types-de-simplification' => 'dlnuf')).to eq([cantine])
      expect(described_class.catalogue('categorie-de-solution' => 'logiciel-metier')).to eq([cantine])
      expect(described_class.catalogue('fournisseurs-de-service' => 'tout-acteurs-publics')).to eq([cantine])
      expect(described_class.catalogue('fournisseurs-de-service' => 'etat', 'target-users' => 'particuliers')).to be_empty
      expect(described_class.catalogue('target-users' => '')).to eq([cantine, marches])
    end

    it 'cherche par sous-chaîne, sans accents, dans le nom, le chapo et les mots-clefs, tous les termes requis' do
      expect(described_class.catalogue('q' => 'entre')).to eq([marches])
      expect(described_class.catalogue('q' => 'demarche')).to eq([cantine])
      expect(described_class.catalogue('q' => 'repas')).to eq([cantine])
      expect(described_class.catalogue('q' => 'cantine familles')).to eq([cantine])
      expect(described_class.catalogue('q' => 'cantine entreprises')).to be_empty
      expect(described_class.catalogue('q' => '%')).to be_empty
    end

    it 'trie par date de création ou de mise à jour, pertinence sinon' do
      expect(described_class.catalogue('sort' => '-created')).to eq([cantine, marches])
      expect(described_class.catalogue('sort' => '-last_modified')).to eq([marches, cantine])
      expect(described_class.catalogue('sort' => 'autre')).to eq([cantine, marches])
    end
  end
end
