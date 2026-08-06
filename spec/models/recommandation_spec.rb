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

  describe '.visibles' do
    it 'returns only visible recommandations' do
      demarche = Demarche.create!(nom: 'Démarche')
      solution = Solution.create!(nom: 'Solution')
      visible = described_class.create!(demarche:, solution:, visible: true)
      described_class.create!(demarche:, solution:, visible: false)

      expect(described_class.visibles).to contain_exactly(visible)
    end
  end
end
