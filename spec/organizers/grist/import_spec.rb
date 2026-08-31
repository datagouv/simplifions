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
    expect(Recommandation.count).to eq(12)
    expect(Integration.count).to eq(20)
  end

  it 'imports demarches with their vocabularies, keywords and snapshot slug' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    expect(cantine).to have_attributes(
      nom: 'Tarification cantine scolaire à 1€',
      visible: true,
      slug: 'tarification-cantine-scolaire-a-1eur',
      cree_le: Time.zone.parse('2025-09-29T12:14:26.813Z')
    )
    expect(cantine.mots_clefs).to include('cantine', 'repas')
    expect(cantine.vocabulaires.categorie_usager.pluck(:nom)).to contain_exactly('Particuliers')
    expect(cantine.types_acteurs.pluck(:nom)).to contain_exactly('Communes et groupements de communes')
    expect(cantine.modifie_le).to be_present
  end

  it 'falls back to a parameterized slug for records outside the topics snapshot' do
    result
    eau = Demarche.find_by!(grist_id: 'Cas_d_usages:6')
    expect(eau).to have_attributes(visible: false, slug: 'tarification-sociale-de-l-eau-potable', cree_le: nil)
  end

  it 'unifies Grist Solutions and APIs_et_datasets into solutions with mapped categories' do
    result
    bouquet = Solution.find_by!(grist_id: 'Solutions:1')
    expect(bouquet).to have_attributes(categorie: 'brique_logicielle', slug: 'bouquet-api-particulier', visible: true,
      cree_le: Time.zone.parse('2025-09-29T12:14:33.730Z'))
    expect(bouquet.organisations.pluck(:nom)).to contain_exactly('DINUM')
    expect(bouquet.vocabulaires.categorie_type_simplification).to be_present

    api_qf = Solution.find_by!(grist_id: 'APIs_et_datasets:1')
    expect(api_qf).to have_attributes(categorie: 'api', france_connectee: true, slug: nil)

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

  it 'imports FranceConnect integrations as ordinary consomme rows' do
    result
    fc = Integration.find_by!(grist_id: 'API_et_datasets_integres:101')
    expect(fc.type_integration).to eq('consomme')
    expect(fc.integree.nom).to eq('API FranceConnect')
  end

  it 'resolves the single recommandation target from either Grist column, at niveau 2' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    cibles = cantine.recommandations.niveau_2.map { |reco| reco.solution.grist_id }
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

  it 'merges the utiles table into niveau 1 recommandations, blank ones born from fournis scoping' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    api_qf = Solution.find_by!(grist_id: 'APIs_et_datasets:1')
    reco = Recommandation.find_by!(demarche: cantine, solution: api_qf)
    expect(reco).to have_attributes(niveau: 'niveau_1', ordre: 1)
    expect(reco.description).to start_with('Récupérer le quotient familial')

    eau = Demarche.find_by!(grist_id: 'Cas_d_usages:6')
    expect(eau.recommandations.niveau_1.where(description: [nil, ''])).to be_present
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
    paire_fantome = Recommandation.create!(demarche: cantine, solution: Solution.find_by!(grist_id: 'APIs_et_datasets:45'))

    relance = described_class.call

    expect(Solution.exists?(fantome.id)).to be(false)
    expect(Recommandation.exists?(paire_fantome.id)).to be(false)
    expect(relance.report[:notes].join).to include('Solution')
  end

  it 'fails with a report instead of crashing when Grist is unreachable' do
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Solutions/records").to_raise(SocketError)
    expect(result).to be_a_failure
    expect(result.error).to include('Solutions')
  end

  it 'refuses to prune a model whose rows were all quarantined this run' do
    result
    operateurs = JSON.parse(Rails.root.join('spec/fixtures/grist/Operateurs.json').read)
    operateurs['records'].each { |record| record['fields']['Name'] = record['fields'].delete('Nom') }
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Operateurs/records")
      .to_return(status: 200, body: operateurs.to_json, headers: { 'Content-Type' => 'application/json' })

    relance = described_class.call

    expect(relance).to be_a_failure
    expect(relance.error).to include('Organisation')
    expect(Organisation.count).to eq(4)
  end

  it 'quarantines rows with blank required values instead of crashing' do
    operateurs = JSON.parse(Rails.root.join('spec/fixtures/grist/Operateurs.json').read)
    operateurs['records'] << { 'id' => 999, 'fields' => { 'Nom' => '' } }
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Operateurs/records")
      .to_return(status: 200, body: operateurs.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(result).to be_a_success
    expect(result.report[:quarantine].join).to include('Operateurs:999')
    expect(Organisation.count).to eq(4)
  end

  it 'quarantines a second Grist source claiming an already imported (demarche, solution) pair' do
    recos = JSON.parse(Rails.root.join('spec/fixtures/grist/Recommandations.json').read)
    recos['records'] << { 'id' => 901, 'fields' => {
      'Cas_d_usage' => 8, 'API_ou_datasets_recommandes' => 1, 'Visible_sur_simplifions' => true
    } }
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Recommandations/records")
      .to_return(status: 200, body: recos.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(result).to be_a_success
    expect(result.report[:quarantine].join).to include('API_et_datasets_utiles:31')

    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    api_qf = Solution.find_by!(grist_id: 'APIs_et_datasets:1')
    paire = Recommandation.find_by!(demarche: cantine, solution: api_qf)
    expect(paire).to have_attributes(grist_id: 'Recommandations:901', niveau: 'niveau_2', description: nil)
  end

  it 'quarantines a recommandation retargeted onto an occupied pair instead of wedging the import' do
    result
    recos = JSON.parse(Rails.root.join('spec/fixtures/grist/Recommandations.json').read)
    reco44 = recos['records'].find { |record| record['id'] == 44 }
    reco44['fields']['Solution_recommandee'] = 0
    reco44['fields']['API_ou_datasets_recommandes'] = 59
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Recommandations/records")
      .to_return(status: 200, body: recos.to_json, headers: { 'Content-Type' => 'application/json' })

    relance = described_class.call

    expect(relance).to be_a_success
    expect(relance.report[:quarantine].join).to include('Recommandations:44')
  end

  it 'converges in one run when an api with an unmapped type gets its type fixed in Grist' do
    result
    api51 = Solution.find_by!(grist_id: 'APIs_et_datasets:51')
    expect(api51.slug).to be_present

    apis = JSON.parse(Rails.root.join('spec/fixtures/grist/APIs_et_datasets.json').read)
    apis['records'].find { |record| record['id'] == 51 }['fields']['Type'] = 'API'
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/APIs_et_datasets/records")
      .to_return(status: 200, body: apis.to_json, headers: { 'Content-Type' => 'application/json' })

    relance = described_class.call

    expect(relance).to be_a_success
    expect(api51.reload).to have_attributes(categorie: 'api', slug: nil)
  end

  it 'quarantines a recommandation putting a privately-operated solution forward' do
    recos = JSON.parse(Rails.root.join('spec/fixtures/grist/Recommandations.json').read)
    recos['records'] << { 'id' => 902, 'fields' => {
      'Cas_d_usage' => 8, 'Solution_recommandee' => 32, 'Visible_sur_simplifions' => true
    } }
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/Recommandations/records")
      .to_return(status: 200, body: recos.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(result).to be_a_success
    expect(result.report[:quarantine].join).to include('Recommandations:902')
    expect(Recommandation.find_by(grist_id: 'Recommandations:902')).to be_nil
  end

  it 'adopts a scoping-born recommandation when a real utiles row appears for the same pair' do
    result
    eau = Demarche.find_by!(grist_id: 'Cas_d_usages:6')
    api9 = Solution.find_by!(grist_id: 'APIs_et_datasets:9')
    nee_du_scoping = Recommandation.find_by!(demarche: eau, solution: api9)

    utiles = JSON.parse(Rails.root.join('spec/fixtures/grist/API_et_datasets_utiles.json').read)
    utiles['records'] << { 'id' => 900, 'fields' => {
      'Cas_d_usage' => 6, 'Api_ou_dataset_utile_fourni_par_une_recommandation' => 9,
      'En_quoi_cette_API_ou_dataset_est_utile_pour_ce_cas_d_usage' => 'Nouvelle description', 'Ordre' => 2
    } }
    stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/API_et_datasets_utiles/records")
      .to_return(status: 200, body: utiles.to_json, headers: { 'Content-Type' => 'application/json' })

    described_class.call

    expect(nee_du_scoping.reload).to have_attributes(
      grist_id: 'API_et_datasets_utiles:900', description: 'Nouvelle description', ordre: 2, niveau: 'niveau_1'
    )
  end

  it 'converges when replayed against a locally modified database, without touching slugs' do
    result
    cantine = Demarche.find_by!(grist_id: 'Cas_d_usages:8')
    cantine.update!(nom: 'Renommée à la main', slug: 'slug-custom', cree_le: Time.zone.parse('2020-01-01'))

    expect { described_class.call }.not_to(change do
      [Demarche.count, Solution.count, Integration.count, Recommandation.count, Vocabulaire.count]
    end)

    expect(cantine.reload).to have_attributes(nom: 'Tarification cantine scolaire à 1€', slug: 'slug-custom',
      cree_le: Time.zone.parse('2020-01-01'))
  end
end
