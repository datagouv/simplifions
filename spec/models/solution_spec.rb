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

  describe '#demarches_simplifiables' do
    it 'liste les démarches visibles recommandant la solution, ou qu’elle intègre en production via une reco visible' do
      bouquet = described_class.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle')
      api_qf = described_class.create!(nom: 'API Quotient familial', categorie: 'api')
      logiciel = described_class.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main')
      portail = described_class.create!(nom: 'Portail agents', categorie: 'site_de_consultation')
      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'expose')

      cantine = Demarche.create!(nom: 'Cantine', visible: true)
      brouillon = Demarche.create!(nom: 'Brouillon', visible: false)
      autre = Demarche.create!(nom: 'Autre', visible: true)
      Recommandation.create!(demarche: cantine, solution: bouquet, niveau: :niveau_2, visible: true)
      Recommandation.create!(demarche: brouillon, solution: bouquet, niveau: :niveau_2, visible: true)
      Recommandation.create!(demarche: autre, solution: bouquet, niveau: :niveau_2, visible: false)

      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production', demarches: [cantine, autre])
      Integration.create!(integratrice: portail, integree: api_qf, type_integration: 'consomme',
        demarches: [cantine])

      expect(bouquet.demarches_simplifiables).to contain_exactly(cantine)
      expect(logiciel.demarches_simplifiables).to contain_exactly(cantine)
      expect(portail.demarches_simplifiables).to be_empty
    end

    it 'suit l’ordre de saisie des recommandations, comme le site actuel' do
      bouquet = described_class.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle')
      zoo = Demarche.create!(nom: 'Zoo', visible: true)
      autre = Demarche.create!(nom: 'Autre', visible: true)
      Recommandation.create!(demarche: zoo, solution: bouquet, niveau: :niveau_2, visible: true)
      Recommandation.create!(demarche: autre, solution: bouquet, niveau: :niveau_2, visible: true)

      expect(bouquet.demarches_simplifiables).to eq([zoo, autre])
    end

    it 'compte l’intégration de la cible elle-même quand la reco vise une API en direct' do
      api = described_class.create!(nom: 'API FranceConnect', categorie: 'api')
      portail = described_class.create!(nom: 'Portail agents', categorie: 'site_de_consultation')
      demarche = Demarche.create!(nom: 'Cantine', visible: true)
      Recommandation.create!(demarche:, solution: api, niveau: :niveau_2, visible: true)
      Integration.create!(integratrice: portail, integree: api, type_integration: 'consomme',
        statut: '✅ en production', demarches: [demarche])

      expect(portail.demarches_simplifiables).to contain_exactly(demarche)
    end
  end

  describe '#consommees' do
    it 'liste les données intégrées en production, pas les exposées ni les intégrations en cours' do
      logiciel = described_class.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main')
      api_qf = described_class.create!(nom: 'API Quotient familial', categorie: 'api')
      api_statut = described_class.create!(nom: 'API Statut étudiant', categorie: 'api')
      api_fc = described_class.create!(nom: 'API FranceConnect', categorie: 'api')
      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production')
      Integration.create!(integratrice: logiciel, integree: api_statut, type_integration: 'consomme',
        statut: '🚧 en cours')
      Integration.create!(integratrice: logiciel, integree: api_fc, type_integration: 'expose')

      expect(logiciel.consommees).to contain_exactly(api_qf)
    end
  end

  describe '#integratrices_visibles' do
    it 'liste les solutions visibles intégrant en production une donnée fournie, cible comprise' do
      bouquet = described_class.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle')
      api_qf = described_class.create!(nom: 'API Quotient familial', categorie: 'api')
      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'expose')

      logiciel = described_class.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main', visible: true)
      brouillon = described_class.create!(nom: 'Portail brouillon', categorie: 'site_de_consultation')
      en_cours = described_class.create!(nom: 'Portail en cours', categorie: 'site_de_consultation', visible: true)
      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production')
      Integration.create!(integratrice: brouillon, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production')
      Integration.create!(integratrice: en_cours, integree: api_qf, type_integration: 'consomme',
        statut: '🚧 en cours')

      expect(bouquet.integratrices_visibles).to contain_exactly(logiciel)
      expect(api_qf.integratrices_visibles).to contain_exactly(logiciel)
    end
  end

  describe '#couvertures' do
    it 'compte par intégratrice et démarche visible les données utiles intégrées (x) sur attendues (y)' do
      bouquet = described_class.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle')
      api_qf = described_class.create!(nom: 'API Quotient familial', categorie: 'api')
      api_statut = described_class.create!(nom: 'API Statut étudiant', categorie: 'api')
      api_extra = described_class.create!(nom: 'API Extra', categorie: 'api')
      [api_qf, api_statut, api_extra].each do |api|
        Integration.create!(integratrice: bouquet, integree: api, type_integration: 'expose')
      end

      cantine = Demarche.create!(nom: 'Cantine', visible: true)
      autre = Demarche.create!(nom: 'Autre', visible: true)
      brouillon = Demarche.create!(nom: 'Brouillon', visible: false)
      Recommandation.create!(demarche: cantine, solution: api_qf, niveau: :niveau_1)
      Recommandation.create!(demarche: cantine, solution: api_statut, niveau: :niveau_1)
      Recommandation.create!(demarche: autre, solution: api_qf, niveau: :niveau_1)

      logiciel = described_class.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main', visible: true)
      portail = described_class.create!(nom: 'Portail agents', categorie: 'site_de_consultation', visible: true)
      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production', demarches: [cantine, autre, brouillon])
      Integration.create!(integratrice: logiciel, integree: api_statut, type_integration: 'consomme',
        statut: '🚧 en cours', demarches: [cantine])
      Integration.create!(integratrice: portail, integree: api_extra, type_integration: 'consomme',
        statut: '✅ en production', demarches: [cantine])

      expect(bouquet.couvertures[logiciel.id]).to eq(cantine => [1, 2], autre => [1, 1])
      expect(bouquet.couvertures[portail.id]).to eq(cantine => [0, 2])
    end
  end

  describe 'normalisation des URLs' do
    it 'neutralise les URLs Grist qui ne sont pas http(s), le contenu étant semi-confiance' do
      solution = described_class.new(nom: 'Louche', categorie: 'brique_logicielle',
        site_internet: 'javascript:alert(1)', url_demande_acces: ' https://datapass.example/ok ')

      expect(solution.site_internet).to be_nil
      expect(solution.url_demande_acces).to eq('https://datapass.example/ok')
    end
  end

  describe '#nb_donnees_integrees' do
    it 'compte les intégrations en production de chaque intégratrice visible, tous fournisseurs confondus' do
      bouquet = described_class.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle')
      api_qf = described_class.create!(nom: 'API Quotient familial', categorie: 'api')
      api_autre = described_class.create!(nom: 'API d’un autre fournisseur', categorie: 'api')
      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'expose')
      logiciel = described_class.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main', visible: true)
      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production')
      Integration.create!(integratrice: logiciel, integree: api_autre, type_integration: 'consomme',
        statut: '✅ en production')

      expect(bouquet.nb_donnees_integrees).to eq(logiciel.id => 2)
    end
  end

  describe '#lien_datagouv' do
    it 'pointe vers la fiche dataservice ou dataset selon la catégorie' do
      expect(described_class.new(categorie: 'api', uid_datagouv: 'abc').lien_datagouv)
        .to eq('https://www.data.gouv.fr/fr/dataservices/abc')
      expect(described_class.new(categorie: 'base_de_donnees', uid_datagouv: 'def').lien_datagouv)
        .to eq('https://www.data.gouv.fr/fr/datasets/def')
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

  describe 'absence of fiche-only fields outside fiches' do
    it 'rejects fiche content, slug or image on an api, accepts them on a fiche' do
      expect(described_class.new(nom: 'API', categorie: 'api', description_courte: 'texte')).not_to be_valid
      expect(described_class.new(nom: 'API', categorie: 'api', slug: 'api-qf')).not_to be_valid

      api = described_class.new(nom: 'API', categorie: 'api')
      api.image.attach(io: StringIO.new('img'), filename: 'i.png', content_type: 'image/png')
      expect(api).not_to be_valid

      fiche = described_class.new(nom: 'Brique', categorie: 'brique_logicielle',
        description_courte: 'texte', slug: 'brique')
      expect(fiche).to be_valid
    end
  end

  describe '.visibles' do
    it 'returns only visible solutions' do
      visible = described_class.create!(nom: 'Publiée', visible: true)
      described_class.create!(nom: 'Brouillon', visible: false)

      expect(described_class.visibles).to contain_exactly(visible)
    end
  end

  describe '#privee?' do
    it 'derives from the operators, false when no operator says so' do
      expect(described_class.create!(nom: 'Acheteza',
        organisations: [Organisation.create!(nom: 'Éditeur SAS', public_ou_prive: 'Privé')])).to be_privee
      expect(described_class.create!(nom: 'Bouquet',
        organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])).not_to be_privee
      expect(described_class.create!(nom: 'Sans opérateur')).not_to be_privee
      expect(described_class.create!(nom: 'Indéterminée',
        organisations: [Organisation.create!(nom: 'Mystère')])).not_to be_privee
    end
  end
end

RSpec.describe Solution, '.catalogue' do
  let(:entreprises) { Vocabulaire.create!(nom: 'Entreprises', slug: 'entreprises', categorie: 'usager') }
  let(:brique) { Vocabulaire.create!(nom: 'Brique technique', slug: 'brique-technique', categorie: 'solution') }
  let!(:bouquet) do
    described_class.create!(nom: 'Bouquet API Entreprise', categorie: 'brique_logicielle', visible: true,
      description_courte: 'Les données des entreprises', vocabulaires: [entreprises, brique],
      types_acteurs: [TypeActeur.create!(nom: 'Communes', slugs: %w[communes tout-acteurs-publics])])
  end
  let!(:eovia) { described_class.create!(nom: 'Eovia', visible: true, description_courte: 'Logiciel de démarches') }

  before do
    described_class.create!(nom: 'API Entreprise cachée', categorie: 'api', visible: true)
    described_class.create!(nom: 'Base entreprises', categorie: 'base_de_donnees', visible: true)
    described_class.create!(nom: 'Brouillon', categorie: 'logiciel_metier_cle_en_main', visible: false)
  end

  it 'liste les fiches visibles seulement, catégorie vide comprise' do
    expect(described_class.catalogue({})).to eq([bouquet, eovia])
  end

  it 'filtre par facettes et cherche sans accents' do
    expect(described_class.catalogue('categorie-de-solution' => 'brique-technique')).to eq([bouquet])
    expect(described_class.catalogue('fournisseurs-de-service' => 'tout-acteurs-publics')).to eq([bouquet])
    expect(described_class.catalogue('target-users' => 'entreprises', 'q' => 'donnees')).to eq([bouquet])
    expect(described_class.catalogue('q' => 'demarche')).to eq([eovia])
  end
end
