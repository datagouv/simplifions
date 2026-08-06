require 'rails_helper'

RSpec.describe Grist::Import do
  subject(:result) { described_class.call }

  before { stub_grist_tables }

  it { is_expected.to be_a_success }

  it 'imports the whole catalogue' do
    result
    expect(Demarche.count).to eq(2)
    expect(Solution.count).to eq(26)
    expect(Vocabulaire.count).to eq(6)
    expect(TypeActeur.count).to eq(5)
    expect(Organisation.count).to eq(4)
    expect(Recommandation.count).to eq(2)
    expect(Integration.count).to eq(20)
  end

  it 'imports demarches with their vocabularies, keywords and snapshot slug' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    expect(cantine).to have_attributes(
      nom: 'Tarification cantine scolaire à 1€',
      visible: true,
      slug: 'tarification-cantine-scolaire-a-1eur'
    )
    expect(cantine.mots_clefs).to include('cantine', 'repas')
    expect(cantine.vocabulaires.categorie_usager.pluck(:nom)).to contain_exactly('Particuliers')
    expect(cantine.types_acteurs.pluck(:nom)).to contain_exactly('Communes et groupements de communes')
    expect(cantine.modifie_le).to be_present
  end

  it 'falls back to a parameterized slug for records outside the topics snapshot' do
    result
    eau = Demarche.find_by!(grist_id: 'Cas_d_usages:6')
    expect(eau).to have_attributes(visible: false, slug: 'tarification-sociale-de-l-eau-potable')
  end

  it 'unifies Grist Solutions and APIs_et_datasets into solutions with mapped categories' do
    result
    bouquet = Solution.find_by!(grist_id: 'Solutions:1')
    expect(bouquet).to have_attributes(categorie: 'brique_logicielle', slug: 'bouquet-api-particulier', visible: true)
    expect(bouquet.organisations.pluck(:nom)).to contain_exactly('DINUM')
    expect(bouquet.vocabulaires.categorie_type_simplification).to be_present

    api_qf = Solution.find_by!(grist_id: 'APIs_et_datasets:1')
    expect(api_qf).to have_attributes(categorie: 'api', france_connectee: true)

    expect(Solution.find_by!(grist_id: 'APIs_et_datasets:45').categorie).to eq('base_de_donnees')
    expect(Solution.find_by!(grist_id: 'Solutions:32').categorie).to eq('logiciel_metier_cle_en_main')
  end

  it 'reports unmappable categories instead of guessing' do
    result
    expect(Solution.find_by!(grist_id: 'APIs_et_datasets:51').categorie).to be_nil
    expect(result.report[:notes].join).to include('APIs_et_datasets:51')
    expect(result.report[:notes].join).to include('Solutions:133')
    expect(Solution.find_by!(grist_id: 'Solutions:133').categorie).to eq('brique_logicielle')
  end

  it 'maps fournis to expose integrations and integres to consomme, scoped to demarches' do
    result
    bouquet = Solution.find_by!(grist_id: 'Solutions:1')
    api_qf = Solution.find_by!(grist_id: 'APIs_et_datasets:1')
    expect(bouquet.exposees).to include(api_qf)

    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    consommation = Integration.find_by!(grist_id: 'API_et_datasets_integres:2')
    expect(consommation).to have_attributes(type_integration: 'consomme', statut: '✅ en production')
    expect(consommation.demarches).to contain_exactly(cantine)
  end

  it 'reclassifies FranceConnect integrations as authentifie' do
    result
    fc = Integration.find_by!(grist_id: 'API_et_datasets_integres:101')
    expect(fc.type_integration).to eq('authentifie')
    expect(fc.integree.nom).to eq('API FranceConnect')
  end

  it 'resolves the single recommandation target from either Grist column' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    cibles = cantine.recommandations.map { |reco| reco.solution.grist_id }
    expect(cibles).to contain_exactly('Solutions:1', 'Solutions:8')
  end

  it 'computes the 4-access-means matrix of the cantine recommendation like the current site' do
    result
    reco = Recommandation.find_by!(grist_id: 'Recommandations:44')
    expect(reco.moyens_acces.transform_values { |sols| sols.map(&:nom) }).to eq(
      'brique_logicielle' => ['Formulaire de collecte du quotient familial'],
      'logiciel_metier_cle_en_main' => ['Acheteza']
    )
  end

  it 'creates utilites from the utiles table and blank ones from fournis scoping, utiles winning' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    api_qf = Solution.find_by!(grist_id: 'APIs_et_datasets:1')
    utilite = Utilite.find_by!(demarche: cantine, solution: api_qf)
    expect(utilite.description).to start_with('Récupérer le quotient familial')
    expect(utilite.ordre).to eq(1)

    eau = Demarche.find_by!(grist_id: 'Cas_d_usages:6')
    expect(Utilite.where(demarche: eau, description: [nil, ''])).to be_present
  end

  it 'quarantines orphan rows with a report instead of crashing' do
    result
    quarantine = result.report[:quarantine].join("\n")
    expect(quarantine).to include('API_et_datasets_integres:496')
    expect(quarantine).to include('Recommandations:195')
    expect(quarantine).to include('API_et_datasets_utiles:60')
    expect(quarantine).to include('API_et_datasets_utiles:64')
    expect(Integration.find_by(grist_id: 'API_et_datasets_integres:496')).to be_nil
  end

  it 'prunes rows that disappeared from Grist' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    fantome = Solution.create!(nom: 'Solution disparue', grist_id: 'Solutions:999')
    paire_fantome = Utilite.create!(demarche: cantine, solution: Solution.find_by!(grist_id: 'APIs_et_datasets:45'))

    relance = described_class.call

    expect(Solution.exists?(fantome.id)).to be(false)
    expect(Utilite.exists?(paire_fantome.id)).to be(false)
    expect(relance.report[:notes].join).to include('Solution')
  end

  it 'fails with a report instead of crashing when Grist is unreachable' do
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Solutions/records").to_raise(SocketError)
    expect(result).to be_a_failure
    expect(result.error).to include('Solutions')
  end

  it 'converges when replayed against a locally modified database, without touching slugs' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    cantine.update!(nom: 'Renommée à la main', slug: 'slug-custom')

    expect { described_class.call }.not_to(change do
      [Demarche.count, Solution.count, Integration.count, Recommandation.count, Utilite.count, Vocabulaire.count]
    end)

    expect(cantine.reload).to have_attributes(nom: 'Tarification cantine scolaire à 1€', slug: 'slug-custom')
  end
end
