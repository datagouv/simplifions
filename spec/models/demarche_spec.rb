require 'rails_helper'

RSpec.describe Demarche do
  it 'garde chaque modification avec ses changements, sans créer de version pour les seules dates' do
    demarche = described_class.create!(nom: 'Cantine')
    demarche.update!(nom: 'Cantine scolaire', modifie_le: Time.current)
    demarche.update!(modifie_le: 1.day.from_now)

    expect(demarche.versions.map(&:event)).to eq(%w[create update])
    expect(demarche.versions.last.changeset).to include('nom' => ['Cantine', 'Cantine scolaire'])
  end

  it 'garde la suppression des recommandations emportées avec la démarche' do
    demarche = described_class.create!(nom: 'Cantine')
    recommandation = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_1)

    demarche.destroy!

    expect(PaperTrail::Version.where(item: recommandation).last.event).to eq('destroy')
  end

  it 'refuse un slug hors format d’URL en disant le format attendu' do
    expect(described_class.new(nom: 'Cantine', slug: 'cantine-scolaire-2')).to be_valid
    ligne = described_class.new(nom: 'Cantine', slug: 'avec espaces/et accents é')
    expect(ligne).not_to be_valid
    expect(ligne.errors.full_messages).to eq(['Slug ne doit contenir que des minuscules sans accent, des chiffres et des tirets'])
  end

  describe '.catalogue' do
    let(:particuliers) { Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager') }
    let(:dlnuf) { Vocabulaire.create!(nom: 'DLNUF', slug: 'dlnuf', categorie: 'type_simplification') }
    let(:logiciel) { Vocabulaire.create!(nom: 'Logiciel métier', slug: 'logiciel-metier', categorie: 'solution') }
    let(:communes) { TypeActeur.create!(nom: 'Communes', slugs: %w[communes tout-collectivites-territoires tout-acteurs-publics]) }
    let!(:cantine) do
      described_class.create!(nom: 'Tarification cantine', slug: 'tarification-cantine', visible: true, cree_le: 1.day.ago, modifie_le: 3.days.ago,
        description_courte: 'Pour les démarches des familles', mots_clefs: %w[repas],
        vocabulaires: [particuliers, dlnuf, logiciel], types_acteurs: [communes])
    end
    let!(:marches) do
      described_class.create!(nom: 'Marchés publics', slug: 'marches-publics', visible: true, cree_le: 2.days.ago, modifie_le: 1.day.ago,
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

  describe '#mots_clefs=' do
    it 'accepte une valeur par ligne, comme dans le formulaire d’administration' do
      expect(described_class.new(mots_clefs: "aides\r\n subventions \n\n").mots_clefs).to eq(%w[aides subventions])
    end

    it 'garde un tableau tel quel, comme à l’import Grist' do
      expect(described_class.new(mots_clefs: %w[aides subventions]).mots_clefs).to eq(%w[aides subventions])
    end
  end

  describe 'brouillon' do
    let(:particuliers) { Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager') }
    let!(:entreprises) { Vocabulaire.create!(nom: 'Entreprises', slug: 'entreprises', categorie: 'usager') }
    let!(:demarche) { described_class.create!(nom: 'Cantine', slug: 'cantine', visible: true, vocabulaires: [particuliers]) }

    def en_base = described_class.find(demarche.id)

    it 'garde Enregistrer d’une démarche publiée à part, sans toucher ses colonnes, ses liaisons ni son historique' do
      expect {
        expect(demarche.enregistrer('nom' => '', 'vocabulaire_ids' => ['', entreprises.id.to_s])).to be(true)
      }.not_to change(PaperTrail::Version, :count)

      expect(en_base.slice(:nom, :visible)).to eq('nom' => 'Cantine', 'visible' => true)
      expect(en_base.vocabulaires).to eq([particuliers])
      expect(en_base).to be_brouillon
    end

    it 'rouvre la démarche sur son brouillon, cases cochées comprises, sans écrire la table de liaison' do
      demarche.enregistrer('nom' => 'Cantine scolaire', 'vocabulaire_ids' => ['', entreprises.id.to_s])

      copie = en_base.appliquer_brouillon
      expect([copie.nom, copie.vocabulaire_ids, copie.vocabulaires.map(&:nom)]).to eq(['Cantine scolaire', [entreprises.id], ['Entreprises']])
      expect(en_base.vocabulaires).to eq([particuliers])
    end

    it 'publie le brouillon complété par le formulaire, avec une version, et le vide' do
      demarche.enregistrer('nom' => 'Cantine scolaire', 'vocabulaire_ids' => [entreprises.id.to_s])

      expect { en_base.enregistrer('description_courte' => 'Repas', 'visible' => '1') }.to change(PaperTrail::Version, :count).by(1)
      expect(en_base.slice(:nom, :description_courte, :visible, :brouillon)).to eq('nom' => 'Cantine scolaire', 'description_courte' => 'Repas', 'visible' => true, 'brouillon' => nil)
      expect(en_base.vocabulaires).to eq([entreprises])
    end

    it 'enregistre un brouillon incomplet et refuse de le publier' do
      demarche.enregistrer('nom' => '')
      ligne = en_base

      expect(ligne.enregistrer('visible' => '1')).to be(false)
      expect(ligne.errors.full_messages).to eq(['Nom doit être rempli'])
      expect(en_base.nom).to eq('Cantine')
      expect(en_base.brouillon).to include('nom' => '')
    end

    it 'masque la démarche publiée en gardant les modifications en brouillon' do
      en_base.enregistrer('nom' => 'Cantine scolaire', 'visible' => '0')

      expect(en_base.slice(:nom, :visible)).to eq('nom' => 'Cantine', 'visible' => false)
      expect(en_base.brouillon).to include('nom' => 'Cantine scolaire')
    end

    it 'ne garde aucun brouillon identique à la version publiée' do
      demarche.enregistrer('nom' => 'Cantine', 'mots_clefs' => '', 'vocabulaire_ids' => ['', particuliers.id.to_s], 'visible' => '0')

      expect(en_base.slice(:visible, :brouillon)).to eq('visible' => false, 'brouillon' => nil)
    end

    it 'compte les retours à la ligne envoyés par le navigateur comme ceux du publié' do
      demarche.update!(contexte: "Repas\nGoûter")
      demarche.enregistrer('contexte' => "Repas\r\nGoûter", 'visible' => '0')

      expect(en_base.brouillon).to be_nil
    end

    it 'compte un champ vide du formulaire comme le champ vide en base' do
      demarche.enregistrer('nom' => 'Cantine', 'contexte' => '', 'cadre_juridique' => '', 'visible' => '0')

      expect(en_base.brouillon).to be_nil
    end

    it 'écrit directement une démarche masquée, brouillon compris, et le vide' do
      demarche.enregistrer('nom' => 'Cantine scolaire', 'description_courte' => 'Repas', 'visible' => '0')

      en_base.enregistrer('description_courte' => 'Repas du midi')
      expect(en_base.slice(:nom, :description_courte, :visible, :brouillon)).to eq('nom' => 'Cantine scolaire', 'description_courte' => 'Repas du midi', 'visible' => false, 'brouillon' => nil)
    end

    it 'abandonne le brouillon pour revenir à la version publiée' do
      demarche.enregistrer('nom' => 'Cantine scolaire')

      en_base.abandonner_brouillon!
      expect(en_base.slice(:nom, :brouillon)).to eq('nom' => 'Cantine', 'brouillon' => nil)
    end
  end
end
