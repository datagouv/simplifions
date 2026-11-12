require 'rails_helper'

RSpec.describe Integration do
  let(:bouquet) { Solution.create!(nom: 'Bouquet') }
  let(:api) { Solution.create!(nom: 'API', categorie: 'api') }

  describe '.en_production' do
    it 'keeps only integrations with the production status' do
      en_prod = described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme',
        statut: '✅ en production')
      described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme',
        statut: '💡 en prospection')

      expect(described_class.en_production).to contain_exactly(en_prod)
    end
  end

  it 'rejects unknown integration types' do
    expect {
      described_class.new(type_integration: 'transporte')
    }.to raise_error(ArgumentError)
  end

  describe 'statut' do
    let(:integration) { described_class.new(integratrice: bouquet, integree: api, type_integration: 'consomme') }

    it 'accepte les statuts Grist et le vide, refuse une saisie hors liste' do
      expect(described_class::STATUTS).to include('🚧 Intéressé si évolution')
      [nil, '', *described_class::STATUTS].each do |statut|
        expect(integration.tap { it.statut = statut }).to be_valid
      end
      integration.statut = 'en production'
      expect(integration).not_to be_valid
      expect(integration.errors.full_messages).to eq(['Statut de l’intégration doit être choisi dans la liste'])
    end
  end

  it 'refuse qu’une solution s’intègre elle-même' do
    integration = described_class.new(integratrice: bouquet, integree: bouquet, type_integration: 'consomme')
    expect(integration).not_to be_valid
    expect(integration.errors.full_messages).to eq(['Une solution ne peut pas s’intégrer elle-même'])
  end

  describe '#libelle' do
    it 'nomme la paire et le sens de l’intégration' do
      integration = described_class.new(integratrice: Solution.new(nom: 'Bouquet'), integree: Solution.new(nom: 'API QF', categorie: 'api'), type_integration: 'consomme')
      expect(integration.libelle).to eq('Bouquet → API QF (API) (intégrée)')
    end
  end

  describe 'démarches de l’intégration' do
    let(:cantine) { Demarche.create!(nom: 'Cantine à 1€') }
    let(:fraude) { Demarche.create!(nom: 'Lutte contre la fraude') }
    let(:integration) { described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme') }

    before do
      Recommandation.create!(demarche: cantine, solution: api, niveau: :niveau_1, visible: false)
      Recommandation.create!(demarche: fraude, solution: Solution.create!(nom: 'API IBAN', categorie: 'api'), niveau: :niveau_1)
    end

    it 'se limitent à celles qui recommandent l’API intégrée, visible ou non' do
      expect(integration.demarches_autorisees).to contain_exactly(cantine)
    end

    it 'refuse une démarche hors règle : seule la démarche autorisée est écrite' do
      integration.demarche_ids = [cantine.id, fraude.id]

      expect(integration.reload.demarches).to contain_exactly(cantine)
      expect(integration).not_to be_valid
      expect(integration.errors.full_messages)
        .to eq(['La démarche « Lutte contre la fraude » ne recommande pas l’API ou le jeu de données intégré'])
    end

    it 'revérifie les démarches gardées quand l’API change' do
      integration.update!(demarches: [cantine])
      integration.integree = fraude.recommandations.first.solution

      expect(integration).not_to be_valid
      expect(integration.errors.full_messages)
        .to eq(['La démarche « Cantine à 1€ » ne recommande pas l’API ou le jeu de données intégré'])
    end

    it 'refuse aussi une démarche hors règle à la création' do
      nouvelle = described_class.new(integratrice: bouquet, integree: api, type_integration: 'consomme',
        demarche_ids: [fraude.id])

      expect(nouvelle.save).to be(false)
      expect(described_class.count).to eq(0)
    end

    it 'refuse l’intégration hors règle depuis la démarche' do
      fraude.update(integration_ids: [integration.id])

      expect(fraude.reload.integrations).to be_empty
      expect(fraude.errors.full_messages)
        .to eq(["L’intégration « #{integration.libelle} » porte sur une API ou un jeu de données que la démarche ne recommande pas"])
    end
  end

  describe '#deplacer_a' do
    let(:noms) { ['API Alpha', 'API Beta', 'API Gamma', 'API Delta'] }
    let!(:fournies) do
      noms.zip([2, nil, 1, nil]).map do |nom, ordre|
        described_class.create!(integratrice: bouquet, integree: Solution.create!(nom:, categorie: 'api'),
          type_integration: 'expose', ordre:)
      end
    end
    let(:alpha) { fournies[0] }
    let(:delta) { fournies[3] }

    def ordre_public = bouquet.api_fournies_dans_l_ordre.map(&:nom)

    it 'part de l’ordre public et renumérote les API fournies de 1 à n' do
      expect(ordre_public).to eq(['API Gamma', 'API Alpha', 'API Beta', 'API Delta'])

      expect(delta.deplacer_a(1)).to be(true)

      expect(ordre_public).to eq(['API Delta', 'API Gamma', 'API Alpha', 'API Beta'])
      expect(fournies.map { it.reload.ordre }).to eq([3, 4, 2, 1])
    end

    it 'garde la position dans les bornes de la liste' do
      alpha.deplacer_a(99)
      expect(ordre_public.last).to eq('API Alpha')

      alpha.deplacer_a(0)
      expect(ordre_public.first).to eq('API Alpha')
    end

    it 'ne touche pas aux intégrations de la solution ni aux API fournies par une autre' do
      integree = described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme', ordre: 7)
      autre = described_class.create!(integratrice: Solution.create!(nom: 'Autre'), integree: api, type_integration: 'expose', ordre: 5)

      delta.deplacer_a(1)

      expect([integree.reload.ordre, autre.reload.ordre]).to eq([7, 5])
    end

    it 'n’écrit, et ne versionne, que les lignes dont le rang change' do
      fournies.each.with_index(1) { |fournie, rang| fournie.update!(ordre: rang) }

      expect { fournies[2].deplacer_a(4) }.to change(PaperTrail::Version, :count).by(2)
      expect(fournies.map { it.reload.ordre }).to eq([1, 2, 4, 3])
    end

    it 'refuse de ranger une API intégrée' do
      integree = described_class.create!(integratrice: bouquet, integree: api, type_integration: 'consomme')

      expect(integree.deplacer_a(1)).to be(false)
      expect(integree.errors.full_messages).to eq(['Seule une API ou un jeu de données fourni se range'])
      expect(fournies.map { it.reload.ordre }).to eq([2, nil, 1, nil])
    end
  end
end
