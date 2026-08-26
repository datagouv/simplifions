require 'rails_helper'

RSpec.describe Recommandation do
  describe '#moyens_acces' do
    it 'groups by categorie the in-production integrators of the target and its exposed solutions, scoped to the demarche' do
      cantine = Demarche.create!(nom: 'Cantine à 1€')
      autre_demarche = Demarche.create!(nom: 'Autre démarche')

      bouquet = Solution.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle')
      api_qf = Solution.create!(nom: 'API Quotient familial', categorie: 'api')
      logiciel = Solution.create!(nom: 'Logiciel cantine', categorie: 'logiciel_metier_cle_en_main')
      portail = Solution.create!(nom: 'Portail agents', categorie: 'site_de_consultation')
      prospect = Solution.create!(nom: 'Éditeur en prospection', categorie: 'logiciel_metier_cle_en_main')
      hors_demarche = Solution.create!(nom: 'Éditeur hors démarche', categorie: 'logiciel_metier_cle_en_main')

      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'expose')
      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production', demarches: [cantine])
      Integration.create!(integratrice: portail, integree: bouquet, type_integration: 'consomme',
        statut: '✅ en production', demarches: [cantine])
      Integration.create!(integratrice: prospect, integree: api_qf, type_integration: 'consomme',
        statut: '💡 en prospection', demarches: [cantine])
      Integration.create!(integratrice: hors_demarche, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production', demarches: [autre_demarche])

      reco = described_class.create!(demarche: cantine, solution: bouquet)

      expect(reco.moyens_acces).to eq(
        'logiciel_metier_cle_en_main' => [logiciel],
        'site_de_consultation' => [portail]
      )
    end
  end

  describe 'contrainte politique' do
    it 'refuses a recommandation putting a privately-operated solution forward, when deducible' do
      demarche = Demarche.create!(nom: 'Démarche')
      privee = Solution.create!(nom: 'Acheteza',
        organisations: [Organisation.create!(nom: 'Éditeur SAS', public_ou_prive: 'Privé')])
      publique = Solution.create!(nom: 'Bouquet API Particulier',
        organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      sans_operateur = Solution.create!(nom: 'API Quotient familial', categorie: 'api')

      expect(described_class.new(demarche:, solution: privee)).not_to be_valid
      expect(described_class.new(demarche:, solution: publique)).to be_valid
      expect(described_class.new(demarche:, solution: sans_operateur, niveau: :niveau_1)).to be_valid
    end
  end

  describe '.visibles' do
    it 'returns only visible recommandations' do
      demarche = Demarche.create!(nom: 'Démarche')
      visible = described_class.create!(demarche:, solution: Solution.create!(nom: 'Publiée'), visible: true)
      described_class.create!(demarche:, solution: Solution.create!(nom: 'Brouillon'), visible: false)

      expect(described_class.visibles).to contain_exactly(visible)
    end
  end
end
