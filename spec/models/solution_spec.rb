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
