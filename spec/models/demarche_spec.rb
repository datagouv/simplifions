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

  describe '#page_publique?' do
    it 'n’a une page publique que visible et avec un slug' do
      expect(described_class.new(visible: true, slug: 'cantine')).to be_page_publique
      expect(described_class.new(visible: false, slug: 'cantine')).not_to be_page_publique
      expect(described_class.new(visible: true, slug: nil)).not_to be_page_publique
    end
  end

  describe '#recommandations_publiees' do
    it 'liste les solutions recommandées visibles dans l’ordre éditorial, sans les données utiles' do
      demarche = described_class.create!(nom: 'Cantine')
      dinum = Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')
      seconde = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Bouquet', organisations: [dinum]), niveau: :niveau_2, ordre: 2, visible: true)
      premiere = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Portail', organisations: [dinum]), niveau: :niveau_2, ordre: 1, visible: true)
      Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Masquée', organisations: [dinum]), niveau: :niveau_2, visible: false)
      Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_1, visible: true)

      expect(demarche.recommandations_publiees).to eq([premiere, seconde])
    end
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

  describe '#integratrices_par_categorie' do
    let(:demarche) { described_class.create!(nom: 'Marchés publics', slug: 'marches-publics', visible: true) }
    let(:bodacc) { Solution.create!(nom: 'API BODACC', categorie: 'api') }
    let(:bio) { Solution.create!(nom: 'API professionnels BIO', categorie: 'api') }
    let(:en_attente) { Solution.create!(nom: 'API pas encore publiée', categorie: 'api') }

    def integratrice(nom, categorie, *apis)
      solution = Solution.create!(nom:, categorie:, visible: true, slug: (nom.parameterize unless categorie == 'api'))
      apis.each do |api|
        Integration.create!(integratrice: solution, integree: api, type_integration: 'consomme', statut: '✅ en production', demarches: [demarche])
      end
      solution
    end

    before do
      bouquet = Solution.create!(nom: 'Bouquet API Entreprise', categorie: 'brique_logicielle',
        organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      [bodacc, bio, en_attente].each { Integration.create!(integratrice: bouquet, integree: it, type_integration: 'expose') }
      Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, visible: true)
      [bodacc, bio].each { Recommandation.create!(demarche:, solution: it, niveau: :niveau_1, visible: true) }
      Recommandation.create!(demarche:, solution: en_attente, niveau: :niveau_1, brouillon: { 'visible' => '1' })
    end

    it 'range par catégorie, logiciels métier d’abord, les plus intégrées puis par nom' do
      zeta = integratrice('Zeta', 'logiciel_metier_cle_en_main', bodacc, bio)
      beta = integratrice('Beta', 'logiciel_metier_cle_en_main', bio)
      alpha = integratrice('Alpha', 'logiciel_metier_cle_en_main', bodacc)
      brique = integratrice('Brique marchés', 'brique_logicielle', bodacc)
      site = integratrice('Site BODACC', 'site_de_consultation', bodacc)

      expect(demarche.integratrices_par_categorie).to eq(
        logiciel_metier_cle_en_main: [zeta, alpha, beta], brique_logicielle: [brique], site_de_consultation: [site]
      )
      expect(demarche.integratrices_par_categorie.keys).to eq(%i[logiciel_metier_cle_en_main brique_logicielle site_de_consultation])
    end

    it 'départage à égalité par ordre alphabétique, sans tenir compte des majuscules ni des accents' do
      local = integratrice('Local Trust', 'logiciel_metier_cle_en_main', bodacc)
      klekoon = integratrice('klekoon.com', 'logiciel_metier_cle_en_main', bodacc)
      editeur = integratrice('Éditeur marchés', 'logiciel_metier_cle_en_main', bodacc)
      zeta = integratrice('Zeta', 'logiciel_metier_cle_en_main', bodacc)

      expect(demarche.integratrices_par_categorie[:logiciel_metier_cle_en_main]).to eq([editeur, klekoon, local, zeta])
    end

    it 'écarte les solutions sans donnée utile publiée intégrée, les API et les catégories vides' do
      logiciel = integratrice('Acheteza', 'logiciel_metier_cle_en_main', bodacc)
      integratrice('Attente', 'logiciel_metier_cle_en_main', en_attente)
      integratrice('API relais', 'api', bodacc)

      expect(demarche.integratrices_par_categorie).to eq(logiciel_metier_cle_en_main: [logiciel])
    end
  end

  describe 'brouillon' do
    let(:particuliers) { Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager') }
    let!(:entreprises) { Vocabulaire.create!(nom: 'Entreprises', slug: 'entreprises', categorie: 'usager') }
    let!(:demarche) { described_class.create!(nom: 'Cantine', slug: 'cantine', visible: true, vocabulaires: [particuliers]) }

    def en_base = described_class.find(demarche.id)

    it 'garde Enregistrer d’une démarche publiée à part, sans toucher ses colonnes ni ses liaisons' do
      expect(demarche.enregistrer('nom' => '', 'vocabulaire_ids' => ['', entreprises.id.to_s])).to be(true)

      expect(en_base.slice(:nom, :visible)).to eq('nom' => 'Cantine', 'visible' => true)
      expect(en_base.vocabulaires).to eq([particuliers])
      expect(en_base).to be_brouillon
    end

    it 'inscrit le brouillon enregistré dans l’historique, avec son auteur' do
      PaperTrail.request(whodunnit: '7') { demarche.enregistrer('nom' => 'Cantine scolaire') }

      version = en_base.versions.last
      expect(version.slice(:event, :whodunnit)).to eq('event' => 'brouillon', 'whodunnit' => '7')
      expect(version.changeset['brouillon'].last).to include('nom' => 'Cantine scolaire')
    end

    it 'dit quels champs chaque enregistrement du brouillon a changés, avant et après' do
      demarche.enregistrer('nom' => 'Cantine scolaire', 'mots_clefs' => '', 'vocabulaire_ids' => [entreprises.id.to_s])
      en_base.enregistrer('nom' => 'Cantine du midi', 'mots_clefs' => "repas\r\ngoûter")

      premier, second = en_base.versions.where(event: 'brouillon').map { described_class.changements_du_brouillon(it) }
      expect(premier).to eq('nom' => ['Cantine', 'Cantine scolaire'])
      expect(second).to eq('nom' => ['Cantine scolaire', 'Cantine du midi'], 'mots_clefs' => [[], %w[repas goûter]])
    end

    it 'n’inscrit rien quand le brouillon reste identique à la version publiée' do
      expect { demarche.enregistrer('nom' => 'Cantine') }.not_to change(PaperTrail::Version, :count)
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

    it 'abandonne le brouillon pour revenir à la version publiée, avec une ligne dans l’historique' do
      demarche.enregistrer('nom' => 'Cantine scolaire')

      en_base.abandonner_brouillon!
      expect(en_base.slice(:nom, :brouillon)).to eq('nom' => 'Cantine', 'brouillon' => nil)
      expect(described_class.changements_du_brouillon(en_base.versions.last)).to eq('nom' => ['Cantine scolaire', 'Cantine'])
      expect(en_base.versions.last.event).to eq('abandon')
    end

    it 'nomme publication la version qui publie le brouillon, modification celle d’une démarche masquée sans brouillon' do
      demarche.enregistrer('nom' => 'Cantine scolaire')
      en_base.enregistrer('visible' => '1')
      expect(en_base.versions.last.slice(:event, :object_changes)).to match('event' => 'publication', 'object_changes' => include('nom' => ['Cantine', 'Cantine scolaire']))

      en_base.update!(visible: false)
      en_base.enregistrer('nom' => 'Cantine du midi')
      expect(en_base.versions.last.event).to eq('update')
    end

    it 'n’écrit pas Publication pour une démarche masquée qui garde un brouillon, enregistrée sans être publiée' do
      demarche.enregistrer('nom' => 'Cantine scolaire', 'visible' => '0')
      en_base.enregistrer('description_courte' => 'Repas')

      expect(en_base.versions.last.slice(:event, :object_changes)).to match('event' => 'update', 'object_changes' => include('nom' => ['Cantine', 'Cantine scolaire']))
    end

    it 'nomme publication la version de chaque recommandation publiée avec la démarche' do
      recommandation = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_2, donnees_utiles: 'Quotient', visible: true)
      recommandation.enregistrer('donnees_utiles' => 'Revenu fiscal')

      expect { en_base.enregistrer('visible' => '1') }.to change(recommandation.versions, :count).by(1)
      expect(recommandation.versions.last.event).to eq('publication')
    end
  end
end
