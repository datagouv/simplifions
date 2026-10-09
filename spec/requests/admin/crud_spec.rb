require 'rails_helper'

RSpec.shared_examples 'un CRUD brut' do |modele, chemin|
  let(:cle) { modele.model_name.param_key }
  let(:modification) { { nom: 'Nouveau nom' } }
  let(:nouveaux) { attributs }
  let(:invalide) { [{ nom: '' }, 'Nom doit être rempli'] }
  let!(:ligne) { modele.create!(attributs) }
  let(:nom) { attributs[:nom] }
  let(:nom_cree) { nom }
  let(:nom_liste) { nom }
  let(:fiche) { ->(id) { "/admin/#{chemin}/#{id}/edit" } }

  def fil_d_ariane = response.parsed_body.css('.fr-breadcrumb__list li').map { |etape| etape.text.strip }

  it 'exige la connexion' do
    get "/admin/#{chemin}"
    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'liste les lignes avec un lien vers leur fiche' do
    sign_in admin
    get "/admin/#{chemin}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<td>#{ligne.id}</td>")
    expect(response.parsed_body.at_css("tbody a[href=\"#{fiche.call(ligne.id)}\"]").text).to eq(nom_liste)
    expect(response.body).not_to include('Supprimer')
    expect(response.parsed_body.css('tbody a').map(&:text)).not_to include('Modifier')
  end

  it 'filtre la liste sur le nom, sans tenir compte des accents ni de la casse' do
    sign_in admin
    get "/admin/#{chemin}", params: { q: I18n.transliterate(nom.split.first).upcase }
    expect(response.body).to include("href=\"#{fiche.call(ligne.id)}\"")
    expect(response.parsed_body.at_css('input[name=q]')['value']).to eq(I18n.transliterate(nom.split.first).upcase)
    get "/admin/#{chemin}", params: { q: 'introuvable' }
    expect(response.body).not_to include("href=\"#{fiche.call(ligne.id)}\"")
  end

  it 'propose la suppression depuis la fiche, en nommant la ligne' do
    sign_in admin
    get "/admin/#{chemin}/#{ligne.id}/edit"
    formulaire = response.parsed_body.at_css("form[action=\"/admin/#{chemin}/#{ligne.id}\"]:has(input[name=_method][value=delete])")
    expect(formulaire['data-turbo-confirm']).to start_with("Supprimer « #{nom} » ?")
  end

  it 'situe chaque page dans le fil d’Ariane de l’administration' do
    sign_in admin
    get "/admin/#{chemin}"
    expect(fil_d_ariane).to eq(['Administration', collection])
    get "/admin/#{chemin}/new"
    expect(fil_d_ariane).to eq(['Administration', collection, 'Nouvelle ligne'])
    get "/admin/#{chemin}/#{ligne.id}/edit"
    expect(fil_d_ariane).to eq(['Administration', collection, nom])
    expect(response.parsed_body.css('.fr-breadcrumb__list a[href]').pluck('href')).to eq(['/admin', "/admin/#{chemin}"])
  end

  it 'nomme la ligne dans le titre de la page et de l’onglet' do
    sign_in admin
    get "/admin/#{chemin}/#{ligne.id}/edit"
    expect(response.parsed_body.at_css('h1').text).to eq(nom)
    expect(response.parsed_body.at_css('title').text).to start_with("#{nom} — ")
  end

  it 'affiche les formulaires de création et de modification' do
    sign_in admin
    get "/admin/#{chemin}/new"
    expect(response.body).to include("action=\"/admin/#{chemin}\"")
    get "/admin/#{chemin}/#{ligne.id}/edit"
    expect(response.body).to include("action=\"/admin/#{chemin}/#{ligne.id}\"")
  end

  it 'surveille les formulaires pour prévenir avant de quitter une saisie' do
    sign_in admin
    get "/admin/#{chemin}/new"
    expect(response.parsed_body.at_css('form[data-controller="formulaire-modifie"]')['action']).to eq("/admin/#{chemin}")
    get "/admin/#{chemin}/#{ligne.id}/edit"
    expect(response.parsed_body.at_css('form[data-controller="formulaire-modifie"]')['action']).to eq("/admin/#{chemin}/#{ligne.id}")
    expect(response.parsed_body.at_css('[data-formulaire-modifie-modifie-value="true"]')).to be_nil
  end

  it 'nomme la ligne telle qu’en base et compte la saisie comme modifiée quand elle est refusée' do
    sign_in admin
    patch "/admin/#{chemin}/#{ligne.id}", params: { cle => invalide.first }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.at_css('form[data-turbo-confirm]')['data-turbo-confirm']).to start_with("Supprimer « #{nom} » ?")
    expect(response.parsed_body.at_css('form[data-controller="formulaire-modifie"]')['data-formulaire-modifie-modifie-value']).to eq('true')
    expect(response.parsed_body.at_css('h1').text).to eq(nom)
    expect(fil_d_ariane.last).to eq(nom)
  end

  it 'crée une ligne et reste sur sa fiche, en la nommant' do
    sign_in admin
    expect { post "/admin/#{chemin}", params: { cle => nouveaux } }.to change(modele, :count).by(1)
    expect(response).to redirect_to(fiche.call(modele.last.id))
    follow_redirect!
    expect(response.body).to include("« #{nom_cree} » enregistré.")
  end

  it 'refuse une ligne invalide et réaffiche le formulaire avec l’erreur' do
    sign_in admin
    post "/admin/#{chemin}", params: { cle => invalide.first }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.at_css('.fr-alert--error a').text).to eq(invalide.last)
  end

  it 'montre l’identifiant Grist en texte sans le laisser modifier' do
    sign_in admin
    ligne.update!(grist_id: 'Table:1')
    get "/admin/#{chemin}/#{ligne.id}/edit"
    expect(response.body).to include('Identifiant Grist : Table:1')
    expect(response.body).not_to include("#{cle}[grist_id]")

    patch "/admin/#{chemin}/#{ligne.id}", params: { cle => modification.merge(grist_id: 'Table:2') }
    expect(ligne.reload.grist_id).to eq('Table:1')
    post "/admin/#{chemin}", params: { cle => nouveaux.merge(grist_id: 'Table:3') }
    expect(modele.last.grist_id).to be_nil
  end

  it 'n’affiche pas d’identifiant Grist sur une ligne qui n’en a pas' do
    sign_in admin
    get "/admin/#{chemin}/new"
    expect(response.body).not_to include('Identifiant Grist')
  end

  it 'modifie une ligne et reste sur sa fiche, en la nommant' do
    sign_in admin
    patch "/admin/#{chemin}/#{ligne.id}", params: { cle => modification }
    expect(response).to redirect_to(fiche.call(ligne.id))
    expect(ligne.reload.attributes).to include(modification.stringify_keys)
    follow_redirect!
    expect(response.parsed_body.at_css('.fr-alert').text.strip).to eq("« #{modification[:nom] || nom} » enregistré.")
    expect(response.parsed_body.at_css('title').text).to start_with("« #{modification[:nom] || nom} » enregistré. — ")
  end

  it 'supprime une ligne' do
    sign_in admin
    expect { delete "/admin/#{chemin}/#{ligne.id}" }.to change(modele, :count).by(-1)
    expect(response).to redirect_to("/admin/#{chemin}")
    follow_redirect!
    expect(response.body).to include("« #{nom} » supprimé.")
  end
end

RSpec.describe 'Administration' do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }

  def colonnes(chemin)
    get "/admin/#{chemin}"
    entetes = response.parsed_body.css('thead th').map(&:text)
    response.parsed_body.css('tbody tr').map { |ligne| entetes.zip(ligne.css('td').map { |cellule| cellule.text.squish }).to_h.except('Id') }
  end

  it_behaves_like 'un CRUD brut', Demarche, 'demarches' do
    let(:collection) { 'Démarches' }
    let(:attributs) { { nom: 'Aides publiques' } }
  end

  it_behaves_like 'un CRUD brut', Solution, 'solutions' do
    let(:collection) { 'Solutions' }
    let(:attributs) { { nom: 'Bouquet API Particulier' } }
  end

  it_behaves_like 'un CRUD brut', Recommandation, 'recommandations' do
    let(:collection) { 'Recommandations' }
    let(:attributs) { { demarche_id: Demarche.create!(nom: 'Aides').id, solution_id: Solution.create!(nom: 'API QF', categorie: 'api').id, niveau: 'niveau_1' } }
    let(:modification) { { ordre: 3 } }
    let(:invalide) { [{ demarche_id: '' }, 'Choisissez une démarche'] }
    let(:nouveaux) { attributs.merge(demarche_id: Demarche.create!(nom: 'Autre démarche').id) }
    let(:nom) { 'Aides → API QF (API)' }
    let(:nom_cree) { 'Autre démarche → API QF (API)' }
  end

  it_behaves_like 'un CRUD brut', Integration, 'integrations' do
    let(:collection) { 'Intégrations' }
    let(:attributs) do
      { integratrice_id: Solution.create!(nom: 'Bouquet').id, integree_id: Solution.create!(nom: 'API QF').id, type_integration: 'expose' }
    end
    let(:modification) { { statut: '✅ en production' } }
    let(:invalide) { [{ integratrice_id: '' }, 'Choisissez une solution'] }
    let(:nom) { 'Bouquet → API QF (fournie)' }
    let(:nom_liste) { 'Bouquet' }
  end

  it_behaves_like 'un CRUD brut', Organisation, 'organisations' do
    let(:collection) { 'Organisations' }
    let(:attributs) { { nom: 'DINUM' } }
  end

  it_behaves_like 'un CRUD brut', TypeActeur, 'types_acteurs' do
    let(:collection) { 'Fournisseurs de services' }
    let(:attributs) { { nom: 'Communes' } }
    let(:fiche) { ->(id) { "/admin/types_acteurs/#{id}" } }
  end

  it_behaves_like 'un CRUD brut', Vocabulaire, 'vocabulaires' do
    let(:collection) { 'Vocabulaires' }
    let(:attributs) { { nom: 'Particuliers', slug: 'particuliers', categorie: 'usager' } }
    let(:fiche) { ->(id) { "/admin/vocabulaires/#{id}" } }
  end

  it 'range à part, sur l’accueil, les tables modifiées rarement' do
    sign_in admin
    get '/admin'
    rubriques = response.parsed_body.css('h2').to_h { |titre| [titre.text, titre.next_element.css('a').map(&:text)] }
    expect(rubriques.slice('Catalogue', 'Référentiels')).to eq(
      'Catalogue' => %w[Démarches Solutions Recommandations Intégrations Organisations],
      'Référentiels' => ['Fournisseurs de services', 'Vocabulaires']
    )
  end

  describe 'recherche dans les listes' do
    before { sign_in admin }

    def noms_listes(chemin, recherche)
      get "/admin/#{chemin}", params: { q: recherche }
      response.parsed_body.css('tbody tr').map { |ligne| ligne.css('td')[1].text.strip }
    end

    it 'cherche une solution par son nom' do
      ['Impôt particulier', 'Bouquet'].each { |nom| Solution.create!(nom:) }
      expect(noms_listes('solutions', 'impot')).to eq(['Impôt particulier'])
      expect(response.parsed_body.at_css('[role=status]').text.strip).to eq('1 ligne')
      noms_listes('solutions', '')
      expect(response.parsed_body.at_css('[role=status]').text.strip).to eq('2 lignes')
    end

    it 'cherche une recommandation ou une intégration par les noms qu’elle relie, chaque mot quelque part' do
      aides = Demarche.create!(nom: 'Aides')
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      api_entreprise = Solution.create!(nom: 'API Entreprise', categorie: 'api')
      [api_qf, api_entreprise].each { |solution| Recommandation.create!(demarche: aides, solution:, niveau: :niveau_1) }
      Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api_qf, type_integration: 'consomme')

      expect(noms_listes('recommandations', 'aides qf')).to eq(['Aides → API QF (API)'])
      expect(noms_listes('integrations', 'bouquet qf')).to eq(['Bouquet'])
      expect(noms_listes('integrations', 'entreprise')).to be_empty
    end

    it 'cherche une démarche par sa description, un nombre comme du texte, et ignore les accents saisis' do
      Demarche.create!(nom: 'Étape 1', description_courte: 'Cantine')
      Demarche.create!(nom: 'Autre')
      Organisation.create!(nom: 'Prefecture')

      expect(noms_listes('demarches', '1')).to eq(['Étape 1'])
      expect(noms_listes('demarches', 'cantine etape')).to eq(['Étape 1'])
      expect(noms_listes('organisations', 'PRÉFECTURE')).to eq(['Prefecture'])
      expect(noms_listes('organisations', '%')).to be_empty
    end
  end

  describe 'pagination des listes' do
    before { sign_in admin }

    it 'montre 50 lignes par page et garde la recherche d’une page à l’autre' do
      Demarche.create!(Array.new(60) { |n| { nom: "Aides #{n}" } } + [{ nom: 'Autre' }])

      get '/admin/demarches', params: { q: 'aides' }
      expect(response.parsed_body.css('tbody tr').size).to eq(50)
      expect(response.parsed_body.at_css('.fr-pagination a[title="Page 2"]')['href']).to eq('/admin/demarches?page=2&q=aides')

      get '/admin/demarches', params: { q: 'aides', page: 2 }
      expect(response.parsed_body.css('tbody tr').size).to eq(10)

      get '/admin/demarches', params: { q: 'aides', foo: 'bar', params: { q: 'autre' } }
      expect(response.parsed_body.at_css('.fr-pagination a[title="Page 2"]')['href']).to eq('/admin/demarches?page=2&q=aides')

      get '/admin/demarches', params: { page: ['2'] }
      expect(response.parsed_body.css('tbody tr').size).to eq(50)
    end

    it 'montre toutes les organisations sur une page, pour les chercher avec Ctrl+F' do
      Organisation.create!(Array.new(51) { |n| { nom: "Orga #{n}" } })

      get '/admin/organisations'
      expect(response.parsed_body.css('tbody tr').size).to eq(51)
      expect(response.parsed_body.at_css('[role=status]').text.strip).to eq('51 lignes')
      expect(response.parsed_body.at_css('.fr-pagination')).to be_nil
    end
  end

  describe 'colonnes des listes' do
    before { sign_in admin }

    it 'montre si la démarche, la solution ou la recommandation est visible, et sa date de modification' do
      aides = Demarche.create!(nom: 'Aides', slug: 'aides', visible: true, modifie_le: Time.utc(2026, 10, 4, 23, 30))
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      Recommandation.create!(demarche: aides, solution: api_qf, niveau: :niveau_1, visible: true, modifie_le: Time.zone.local(2026, 3, 1, 12))

      expect(colonnes('demarches')).to eq([{ 'Nom' => 'Aides', 'Visible' => 'Oui', 'Modifié le' => '05/10/2026' }])
      expect(response.parsed_body.at_css('tbody time')['datetime']).to eq('2026-10-05T01:30:00+02:00')
      expect(colonnes('recommandations')).to eq([{ 'Ligne' => 'Aides → API QF (API)', 'Visible' => 'Oui', 'Modifié le' => '01/03/2026' }])
      expect(colonnes('solutions')).to eq([{ 'Nom' => 'API QF (API)', 'Privée' => 'Non', 'Visible' => 'Non', 'Modifié le' => '', 'Intégrée par' => '' }])
    end

    it 'place l’icône d’une démarche devant son nom, sans la lire aux lecteurs d’écran' do
      Demarche.create!(nom: 'Eau', icone: '💧')
      expect(colonnes('demarches').first['Nom']).to eq('💧 Eau')
      expect(response.parsed_body.at_css('tbody [aria-hidden=true]').text).to eq('💧')
    end

    it 'titre les colonnes des intégrations avec les libellés du formulaire' do
      Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: Solution.create!(nom: 'API QF', categorie: 'api'),
        type_integration: 'consomme', statut: '✅ en production')
      expect(colonnes('integrations')).to eq([{ 'Solution' => 'Bouquet', 'API ou jeu de données' => 'API QF (API)', 'Type d’intégration' => 'Intégrée',
                                                'Statut de l’intégration' => '✅ en production' }])
      expect(response.parsed_body.at_css('tbody a')['aria-label']).to eq('Bouquet → API QF (API) (intégrée)')
    end

    it 'montre le nom court et le nom long des organisations' do
      Organisation.create!(nom: 'DINUM', nom_long: 'Direction interministérielle du numérique')
      expect(colonnes('organisations')).to eq([{ 'Nom court' => 'DINUM', 'Nom long' => 'Direction interministérielle du numérique' }])
    end

    it 'nomme les solutions qui intègrent chaque solution, avec un lien vers leur fiche' do
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      bouquet = Solution.create!(nom: 'Bouquet')
      [[bouquet, 'consomme'], [bouquet, 'expose'], [Solution.create!(nom: 'Mes Aides'), 'consomme'], [Solution.create!(nom: 'eTicket'), 'consomme']].each do |integratrice, type_integration|
        Integration.create!(integratrice:, integree: api_qf, type_integration:)
      end

      expect(colonnes('solutions').find { |ligne| ligne['Nom'] == 'API QF (API)' }['Intégrée par']).to eq('Bouquet, eTicket, Mes Aides')
      expect(response.parsed_body.css('tbody td:last-child a').pluck('href')).to include("/admin/solutions/#{bouquet.id}/edit")
    end
  end

  describe 'associations plusieurs-à-plusieurs' do
    before { sign_in admin }

    it 'coche les vocabulaires et types d’acteurs d’une démarche' do
      demarche = Demarche.create!(nom: 'Aides')
      usager = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      communes = TypeActeur.create!(nom: 'Communes')

      get "/admin/demarches/#{demarche.id}/edit"
      expect(response.body).to include("<input type=\"checkbox\" value=\"#{usager.id}\" name=\"demarche[vocabulaire_ids][]\" id=\"demarche_vocabulaire_ids_#{usager.id}\" />")

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { vocabulaire_ids: [usager.id], type_acteur_ids: [communes.id] } }
      expect(demarche.reload.vocabulaires).to eq([usager])
      expect(demarche.types_acteurs).to eq([communes])
    end

    it 'coche les démarches d’une intégration et les solutions d’une organisation' do
      demarche = Demarche.create!(nom: 'Aides')
      bouquet = Solution.create!(nom: 'Bouquet')
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      Recommandation.create!(demarche:, solution: api, niveau: :niveau_1)
      integration = Integration.create!(integratrice: bouquet, integree: api, type_integration: 'consomme')
      dinum = Organisation.create!(nom: 'DINUM')

      patch "/admin/integrations/#{integration.id}", params: { integration: { demarche_ids: [demarche.id] } }
      expect(integration.reload.demarches).to eq([demarche])

      patch "/admin/organisations/#{dinum.id}", params: { organisation: { solution_ids: [bouquet.id] } }
      expect(dinum.reload.solutions).to eq([bouquet])
    end

    describe 'démarches d’une intégration' do
      let(:api) { Solution.create!(nom: 'API QF', categorie: 'api') }
      let(:cantine) { Demarche.create!(nom: 'Cantine') }
      let(:fraude) { Demarche.create!(nom: 'Fraude') }
      let(:ancienne) { Demarche.create!(nom: 'Ancienne') }
      let(:integration) { Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api, type_integration: 'consomme') }
      let(:hors_api) do
        Integration.create!(integratrice: Solution.create!(nom: 'Portail'), integree: Solution.create!(nom: 'API IBAN', categorie: 'api'),
          type_integration: 'consomme')
      end

      def cases(chemin, nom)
        get chemin
        response.parsed_body.css("input[type=checkbox][name$='[#{nom}][]'] + label").map { |libelle| libelle.text.strip }
      end

      before do
        Recommandation.create!(demarche: cantine, solution: api, niveau: :niveau_1, visible: false)
        Recommandation.create!(demarche: fraude, solution: hors_api.integree, niveau: :niveau_1)
        Integration.connection.execute("INSERT INTO demarches_integrations (demarche_id, integration_id) VALUES (#{ancienne.id}, #{integration.id})")
      end

      it 'ne propose que les démarches qui recommandent l’API, et garde à décocher un lien hors règle' do
        expect(cases("/admin/integrations/#{integration.id}/edit", 'demarche_ids')).to eq(['Ancienne (hors règle)', 'Cantine'])
        expect(cases("/admin/demarches/#{cantine.id}/edit", 'integration_ids')).to eq([integration.libelle])
        expect(cases("/admin/demarches/#{ancienne.id}/edit", 'integration_ids')).to eq(["#{integration.libelle} (hors règle)"])
      end

      it 'refuse une démarche hors règle avec un message, sans rien enregistrer' do
        patch "/admin/integrations/#{integration.id}", params: { integration: { demarche_ids: [cantine.id, fraude.id] } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.at_css('.fr-alert--error').text).to include('La démarche « Fraude » ne recommande pas l’API ou le jeu de données intégré')
        expect(integration.reload.demarches).to eq([ancienne])
      end

      it 'refuse de changer l’API d’une intégration dont une démarche ne la recommande pas' do
        patch "/admin/integrations/#{integration.id}", params: { integration: { integree_id: hors_api.integree_id, demarche_ids: [ancienne.id] } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.at_css('.fr-alert--error').text).to include('La démarche « Ancienne » ne recommande pas l’API ou le jeu de données intégré')
        expect(integration.reload.integree).to eq(api)
      end

      it 'garde la décoche d’un lien hors règle quand le formulaire revient en erreur' do
        patch "/admin/demarches/#{ancienne.id}", params: { demarche: { nom: '', integration_ids: [''] } }
        expect(response).to have_http_status(:unprocessable_content)

        formulaire = response.parsed_body.at_css('#formulaire-fiche')
        champs = formulaire.css('input[name^="demarche["]').to_h { |champ| [champ['name'], champ['value']] }
        patch "/admin/demarches/#{ancienne.id}", params: Rack::Utils.parse_nested_query(champs.merge('demarche[nom]' => 'Ancienne').to_query)
        expect(ancienne.reload.integrations).to be_empty
      end

      it 'explique quand cocher les démarches d’une intégration et les intégrations d’une démarche' do
        get '/admin/integrations/new'
        expect(response.parsed_body.css('input[type=checkbox][name="integration[demarche_ids][]"]')).to be_empty
        expect(response.parsed_body.text).to include('Démarches : à cocher une fois l’API ou le jeu de données enregistré')

        get '/admin/demarches/new'
        expect(response.parsed_body.css('input[type=checkbox][name="demarche[integration_ids][]"]')).to be_empty
        expect(response.parsed_body.text).to include('Intégrations : à cocher une fois que la démarche recommande l’API ou le jeu de données intégré')
      end
    end

    it 'groupe les vocabulaires par catégorie, dans l’ordre du Grist' do
      proactivite = Vocabulaire.create!(nom: 'Proactivité', slug: 'proactivite', categorie: 'type_simplification')
      particuliers = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      api = Vocabulaire.create!(nom: 'API', slug: 'api', categorie: 'solution')
      acces = Vocabulaire.create!(nom: 'Accès facile', slug: 'acces-facile', categorie: 'type_simplification')

      %w[demarches solutions].each do |chemin|
        get "/admin/#{chemin}/new"
        vocabulaires = response.parsed_body.at_css('fieldset:has(> legend:contains("Vocabulaires"))')
        groupes = vocabulaires.css('fieldset').to_h do |groupe|
          [groupe.at_css('legend').text.strip, groupe.css('input[type=checkbox]').map { |case_a_cocher| case_a_cocher['value'].to_i }]
        end
        expect(groupes).to eq('Usager' => [particuliers.id], 'Type de simplification' => [proactivite.id, acces.id], 'Catégorie de solution' => [api.id])
      end
    end

    it 'distingue les solutions homonymes par leur catégorie dans chaque choix de solution' do
      api = Solution.create!(nom: 'API Impôt particulier', categorie: 'api')
      fiche = Solution.create!(nom: 'API Impôt particulier', categorie: 'logiciel_metier_cle_en_main')
      attendus = ['API Impôt particulier (API)', 'API Impôt particulier (Logiciel métier)']

      %w[types_acteurs organisations vocabulaires].each do |chemin|
        get "/admin/#{chemin}/new"
        expect(response.parsed_body.css('input[type=checkbox][name$="[solution_ids][]"] + label').map { |libelle| libelle.text.strip }).to eq(attendus)
      end
      { 'recommandations' => %w[recommandation_solution_id], 'integrations' => %w[integration_integree_id integration_integratrice_id] }.each do |chemin, champs|
        get "/admin/#{chemin}/new"
        champs.each { |champ| expect(response.parsed_body.css("##{champ} option").map(&:text).compact_blank).to eq(attendus) }
      end

      Integration.create!(integratrice: fiche, integree: api, type_integration: 'consomme')
      Recommandation.create!(demarche: Demarche.create!(nom: 'Aides'), solution: api, niveau: :niveau_1)
      expect(colonnes('solutions').map { |ligne| ligne.values_at('Nom', 'Intégrée par') })
        .to contain_exactly(['API Impôt particulier (API)', 'API Impôt particulier (Logiciel métier)'], ['API Impôt particulier (Logiciel métier)', ''])
      expect(colonnes('recommandations').pluck('Ligne')).to eq(['Aides → API Impôt particulier (API)'])

      get "/admin/solutions/#{api.id}/edit"
      expect(response.parsed_body.at_css('h1').text).to eq('API Impôt particulier (API)')
      expect(response.parsed_body.at_css('.fr-breadcrumb [aria-current]').text.strip).to eq('API Impôt particulier (API)')

      dgfip = Organisation.create!(nom: 'DGFiP', public_ou_prive: 'Public', solutions: [api, fiche])
      get "/admin/organisations/#{dgfip.id}/edit"
      expect(response.parsed_body.at_css('form[data-turbo-confirm]')['data-turbo-confirm'])
        .to end_with('La solution API Impôt particulier (Logiciel métier) deviendra privée.')
    end

    it 'range chaque longue liste de cases dans un groupe filtrable qui montre tous les choix au clic, sans champ envoyé' do
      {
        'demarches' => ['Fournisseurs de services'], 'solutions' => ['Organisations', 'Fournisseurs de services'],
        'integrations' => [], 'organisations' => ['Solutions'], 'types_acteurs' => %w[Démarches Solutions],
        'vocabulaires' => %w[Démarches Solutions]
      }.each do |chemin, groupes|
        get "/admin/#{chemin}/new"
        filtrables = response.parsed_body.css('fieldset[data-controller="liste-filtrable"]')
        expect(filtrables.map { |groupe| groupe.at_css('legend').text.strip }).to eq(groupes)
        filtrables.each do |groupe|
          filtre = groupe.at_css('input[type=text][data-liste-filtrable-target=filtre]')
          expect(groupe.at_css("label[for=#{filtre['id']}]").text).to include('Filtrer', 'cliquer dans le champ', 'flèche bas')
          expect(filtre['data-action'].split).to include('click->liste-filtrable#ouvrir', 'keydown.down->liste-filtrable#ouvrir')
          expect(groupe.at_css('button[type=button][data-action="liste-filtrable#effacer"]').text.strip).to eq("Effacer le filtre des #{groupe.at_css('legend').text.strip.downcase}")
          expect(groupe['data-action']).to eq('focusout->liste-filtrable#quitter')
          expect(groupe.css('[data-liste-filtrable-target=resultats] input[type=checkbox]').size).to eq(groupe.css('input[type=checkbox]').size)
          expect(filtre['name']).to be_nil
          expect(groupe.at_css('[aria-live=polite]')).to be_present
          expect(groupe.css('input[type=checkbox]')).to all(satisfy { |case_a_cocher| case_a_cocher['name'].end_with?('_ids][]') })
        end
      end
    end
  end

  describe 'textes longs' do
    before { sign_in admin }

    def hauteurs(chemin)
      get chemin
      response.parsed_body.css('textarea').to_h { |zone| [zone['name'], zone['rows'].to_i] }
    end

    it 'donne à chaque zone de texte la hauteur de son contenu, retours à la ligne compris' do
      demarche = Demarche.create!(nom: 'Aides', contexte: "Ligne\n" * 30, cadre_juridique: 'x' * 2900, mots_clefs: %w[a b c d e f g h])

      hauteurs_de_la_fiche = hauteurs("/admin/demarches/#{demarche.id}/edit")
      expect(hauteurs_de_la_fiche).to include('demarche[description_courte]' => 6, 'demarche[contexte]' => 32, 'demarche[mots_clefs]' => 10)
      expect(hauteurs_de_la_fiche['demarche[cadre_juridique]']).to be >= 30
      expect(hauteurs('/admin/demarches/new').values).to all(eq(6))
    end

    it 'signale « Markdown accepté » sur les seuls champs mis en forme sur le site' do
      {
        'demarches' => %w[demarche_contexte demarche_cadre_juridique],
        'solutions' => %w[solution_permet solution_ne_permet_pas],
        'recommandations' => %w[recommandation_donnees_utiles recommandation_parametres_a_saisir recommandation_description],
        'types_acteurs' => []
      }.each do |chemin, champs|
        get "/admin/#{chemin}/new"
        signales = response.parsed_body.css('label:has(.fr-hint-text:contains("Markdown accepté"))').pluck('for')
        expect(signales).to eq(champs)
      end
    end
  end

  describe 'lien vers la page publique' do
    before { sign_in admin }

    def lien_public(chemin)
      get chemin
      response.parsed_body.at_css('a:contains("Voir la page publique")')
    end

    it 'mène à la page publique d’une démarche ou d’une solution visible, annonce le nouvel onglet' do
      demarche = Demarche.create!(nom: 'Aides', slug: 'aides', visible: true)
      solution = Solution.create!(nom: 'Bouquet', slug: 'bouquet', visible: true)

      lien = lien_public("/admin/demarches/#{demarche.id}/edit")
      expect(lien.to_h.slice('href', 'target', 'title')).to eq('href' => '/demarches/aides', 'target' => '_blank', 'title' => 'Voir la page publique de Aides - nouvelle fenêtre')
      expect(lien_public("/admin/solutions/#{solution.id}/edit")['href']).to eq('/solutions/bouquet')
    end

    it 'ne propose aucun lien quand la page publique n’existe pas' do
      expect(lien_public("/admin/demarches/#{Demarche.create!(nom: 'Aides', slug: 'aides').id}/edit")).to be_nil
      expect(lien_public("/admin/solutions/#{Solution.create!(nom: 'API QF', categorie: 'api', visible: true).id}/edit")).to be_nil

      demarche = Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true)
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { slug: 'Mauvais slug', visible: '1' } }
      expect(response.parsed_body.at_css('a:contains("Voir la page publique")')['href']).to eq('/demarches/cantine')
    end
  end

  describe 'liens vers les éléments liés' do
    before { sign_in admin }

    def liens_vers_les_fiches(chemin)
      get chemin
      response.parsed_body.css('a:contains("Voir la fiche")').map { |lien| [lien['aria-label'], lien['href'], lien.ancestors('label').any?] }
    end

    def liens_vers_le_referentiel
      response.parsed_body.css('a:has(.fr-icon-question-line[aria-hidden=true])').map { |lien| [lien.text.strip, lien['href'], lien['target'], lien.ancestors('label').any?] }
    end

    it 'mène depuis chaque case cochée du catalogue à la fiche de l’élément, hors du libellé de la case' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api, type_integration: 'consomme')
      demarche = Demarche.create!(nom: 'Aides', types_acteurs: [TypeActeur.create!(nom: 'Communes')])
      Recommandation.create!(demarche:, solution: api, niveau: :niveau_1)
      demarche.integrations << integration
      usager = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager', solutions: [api])

      expect(liens_vers_les_fiches("/admin/demarches/#{demarche.id}/edit"))
        .to eq([['Voir la fiche Bouquet → API QF (API) (intégrée)', "/admin/integrations/#{integration.id}/edit", false]])
      expect(liens_vers_les_fiches("/admin/vocabulaires/#{usager.id}/edit")).to eq([['Voir la fiche API QF (API)', "/admin/solutions/#{api.id}/edit", false]])
      expect(liens_vers_les_fiches('/admin/demarches/new')).to be_empty
    end

    it 'ouvre dans un nouvel onglet, depuis un « ? » à côté de chaque vocabulaire et fournisseur, sa page de lecture' do
      communes = TypeActeur.create!(nom: 'Communes')
      departements = TypeActeur.create!(nom: 'Départements')
      usager = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      demarche = Demarche.create!(nom: 'Aides', types_acteurs: [communes])
      attendus = [
        ['Fiche de Communes (nouvel onglet)', "/admin/types_acteurs/#{communes.id}", '_blank', false],
        ['Fiche de Départements (nouvel onglet)', "/admin/types_acteurs/#{departements.id}", '_blank', false],
        ['Fiche de Particuliers (nouvel onglet)', "/admin/vocabulaires/#{usager.id}", '_blank', false]
      ]

      ["/admin/demarches/#{demarche.id}/edit", '/admin/solutions/new'].each do |chemin|
        get chemin
        expect(liens_vers_le_referentiel).to match_array(attendus)
      end
    end

    it 'range les vocabulaires et les fournisseurs sur trois colonnes, pas les éléments du catalogue' do
      TypeActeur.create!(nom: 'Communes')
      Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      demarche = Demarche.create!(nom: 'Aides')
      Recommandation.create!(demarche:, solution: api, niveau: :niveau_1)
      Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api, type_integration: 'consomme')
      get "/admin/demarches/#{demarche.id}/edit"
      en_colonnes = response.parsed_body.css('input[type=checkbox]').to_h do |case_a_cocher|
        [case_a_cocher['name'], case_a_cocher.ancestors('.fr-col-12.fr-col-sm-6.fr-col-lg-4').any?]
      end
      expect(en_colonnes).to eq('demarche[type_acteur_ids][]' => true, 'demarche[vocabulaire_ids][]' => true, 'demarche[integration_ids][]' => false)
    end

    it 'mène depuis une recommandation à sa démarche et sa solution, depuis une intégration à ses deux solutions' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      bouquet = Solution.create!(nom: 'Bouquet')
      aides = Demarche.create!(nom: 'Aides')
      recommandation = Recommandation.create!(demarche: aides, solution: api, niveau: :niveau_1)
      integration = Integration.create!(integratrice: bouquet, integree: api, type_integration: 'consomme')

      expect(liens_vers_les_fiches("/admin/recommandations/#{recommandation.id}/edit"))
        .to eq([['Voir la fiche Aides', "/admin/demarches/#{aides.id}/edit", false], ['Voir la fiche API QF (API)', "/admin/solutions/#{api.id}/edit", false]])
      expect(liens_vers_les_fiches("/admin/integrations/#{integration.id}/edit")).to eq([
        ['Voir la fiche API QF (API)', "/admin/solutions/#{api.id}/edit", false],
        ['Voir la fiche Bouquet', "/admin/solutions/#{bouquet.id}/edit", false]
      ])
      expect(liens_vers_les_fiches('/admin/recommandations/new')).to be_empty
    end
  end

  describe 'recommandations depuis la démarche' do
    let(:aides) { Demarche.create!(nom: 'Aides') }

    before { sign_in admin }

    def recommandations_de(chemin)
      get chemin
      tableau = response.parsed_body.at_css('table[aria-labelledby]')
      entetes = tableau.css('thead th').map { it.text.delete_suffix(' (obligatoire)') }
      tableau.css('tbody tr:not(#new_recommandation)').map { |ligne| entetes.zip(ligne.css('td').map { valeur(it) }).to_h.slice('Solution', 'Type de recommandation', 'Ordre') }
    end

    def valeur(cellule) = cellule.at_css('option[selected]')&.text || cellule.at_css('input')&.[]('value') || cellule.text.squish

    it 'liste les recommandations de la démarche par type puis ordre, avec un lien pour en ajouter' do
      recommandation = Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'Mes Aides', categorie: 'api'), niveau: 'niveau_2', ordre: 1)
      Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: 'niveau_1', ordre: 2)
      Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'API Impôt', categorie: 'api'), niveau: 'niveau_1', ordre: 1)
      Recommandation.create!(demarche: Demarche.create!(nom: 'Autre'), solution: Solution.create!(nom: 'Ailleurs', categorie: 'api'), niveau: :niveau_1)

      expect(recommandations_de("/admin/demarches/#{aides.id}/edit")).to eq([
        { 'Solution' => 'API Impôt (API)', 'Type de recommandation' => 'Donnée utile (API ou jeu de données)', 'Ordre' => '1' },
        { 'Solution' => 'API QF (API)', 'Type de recommandation' => 'Donnée utile (API ou jeu de données)', 'Ordre' => '2' },
        { 'Solution' => 'Mes Aides (API)', 'Type de recommandation' => 'Solution recommandée', 'Ordre' => '1' }
      ])
      expect(response.parsed_body.at_css('a:contains("Mes Aides")')['href']).to eq("/admin/recommandations/#{recommandation.id}/edit")
      expect(response.parsed_body.at_css('a:contains("Ajouter une recommandation")')['href'])
        .to eq("/admin/recommandations/new?demarche_id=#{aides.id}")
    end

    it 'propose de modifier chaque recommandation sur sa ligne, dans un formulaire de ligne hors de celui de la fiche' do
      recommandation = Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: 'niveau_1', ordre: 2)
      get "/admin/demarches/#{aides.id}/edit"
      ligne = response.parsed_body.at_css("#onglet-recommandations-panneau tr#recommandation_#{recommandation.id}")
      formulaire = response.parsed_body.at_css("form#formulaire_recommandation_#{recommandation.id}")

      expect(ligne.css('select, input').map { [it['name'], it['form']] }.uniq(&:last)).to eq([['recommandation[solution_id]', formulaire['id']]])
      expect([formulaire['action'], formulaire.at_css('input[name=_method]')['value'], formulaire.ancestors('form').size]).to eq(["/admin/recommandations/#{recommandation.id}", 'patch', 0])
      expect(ligne.at_css("label[for=\"#{ligne.at_css('select')['id']}\"].fr-sr-only").text).to eq('Solution de la recommandation API QF (API) (obligatoire)')
      expect(ligne.at_css('button[type=submit]').then { [it['form'], it.text.squish] }).to eq([formulaire['id'], 'Enregistrer la recommandation API QF (API)'])
      expect(ligne.at_css('a:contains("Modifier")')['href']).to eq("/admin/recommandations/#{recommandation.id}/edit")
    end

    it 'réunit la publication et la date de modification dans une colonne État, pour tenir dans la largeur' do
      Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: 'niveau_1', visible: true, modifie_le: Time.zone.local(2026, 3, 1, 12))
      Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'Mes Aides', categorie: 'api'), niveau: 'niveau_2')
      get "/admin/demarches/#{aides.id}/edit"
      tableau = response.parsed_body.at_css('table[aria-labelledby]')

      expect(tableau.css('thead th').map(&:text)).to eq(['Solution (obligatoire)', 'Type de recommandation (obligatoire)', 'Ordre', 'État', 'Actions'])
      expect(tableau.css('tbody tr').map { it.css('td')[3].text.squish }).to eq(['Publiée 01/03/2026', 'Masquée', ''])
    end

    it 'pré-remplit la démarche d’une nouvelle recommandation' do
      get '/admin/recommandations/new', params: { demarche_id: aides.id }
      expect(response.parsed_body.at_css('#recommandation_demarche_id option[selected]').text).to eq('Aides')
    end

    it 'garde la démarche et ses autres recommandations sous les yeux pendant l’édition d’une recommandation' do
      aides.update!(description_courte: 'Demander une aide sociale')
      recommandation = Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: 'niveau_1')
      Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'Mes Aides', categorie: 'api'), niveau: 'niveau_2', ordre: 4)

      expect(recommandations_de("/admin/recommandations/#{recommandation.id}/edit"))
        .to eq([{ 'Solution' => 'Mes Aides (API)', 'Type de recommandation' => 'Solution recommandée', 'Ordre' => '4' }])
      encart = response.parsed_body.at_css('aside.fr-callout')
      expect(encart.text.squish).to include('Démarche : Aides', 'Demander une aide sociale')
      expect(encart.at_css('a[aria-label="Voir la fiche Aides"]')['href']).to eq("/admin/demarches/#{aides.id}/edit")

      expect(recommandations_de("/admin/recommandations/new?demarche_id=#{aides.id}").size).to eq(2)
    end
  end

  describe 'recommandation enregistrée depuis sa ligne dans la démarche' do
    let!(:aides) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let!(:recommandation) { Recommandation.create!(demarche: aides, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_1, ordre: 1, visible: true) }

    before { sign_in admin }

    def flux = Nokogiri::HTML5.fragment(response.body).css('turbo-stream')
    def ligne_renvoyee = flux.find { it['action'] == 'replace' }.at_css('template tr')
    def choisi(ligne, champ) = ligne.at_css("[name=\"recommandation[#{champ}]\"]").then { it.at_css('option[selected]')&.text || it['value'] }

    it 'renvoie la ligne enregistrée, en brouillon tant que la démarche publiée n’est pas publiée à nouveau' do
      patch "/admin/recommandations/#{recommandation.id}", params: { ligne: 1, recommandation: { niveau: 'niveau_2', ordre: '3' } }

      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(flux.pluck('target')).to eq(['message-recommandations', "recommandation_#{recommandation.id}"])
      expect([choisi(ligne_renvoyee, :niveau), choisi(ligne_renvoyee, :ordre)]).to eq(['Solution recommandée', '3'])
      expect(ligne_renvoyee.text).to include('Brouillon')
      expect(flux.find { it['target'] == 'message-recommandations' }.text.squish).to eq('« Aides → API QF (API) » : brouillon enregistré, non publié.')
      expect(recommandation.reload.ordre).to eq(1)
      get "/admin/demarches/#{aides.id}/edit"
      expect(choisi(response.parsed_body.at_css("tr#recommandation_#{recommandation.id}"), :ordre)).to eq('3')
    end

    it 'renvoie l’erreur sur la ligne, reliée à ses champs' do
      aides.update!(visible: false)
      recommandation.update!(visible: false)
      patch "/admin/recommandations/#{recommandation.id}", params: { ligne: 1, recommandation: { solution_id: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      erreur = ligne_renvoyee.at_css('.fr-error-text')
      expect(erreur.text).to eq('Choisissez une solution')
      expect(ligne_renvoyee.css('select, input, button:not([data-turbo-confirm])').pluck('aria-describedby').uniq).to eq([erreur['id']])
      expect(ligne_renvoyee.at_css('button').text.squish).to eq('Enregistrer la recommandation API QF (API)')
      expect(recommandation.reload.solution).to be_present
    end

    it 'ajoute la recommandation de la ligne vide, puis remet une ligne vide' do
      bouquet = Solution.create!(nom: 'Bouquet', categorie: 'api')
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: aides.id, solution_id: bouquet.id, niveau: 'niveau_2' } }
      nouvelle = Recommandation.find_by!(solution: bouquet)

      expect(flux.map { [it['action'], it['target']] }).to eq([
        %w[update message-recommandations], %w[before new_recommandation], %w[append formulaires-recommandations], %w[replace new_recommandation]
      ])
      expect(choisi(flux[1].at_css('tr'), :solution_id)).to eq('Bouquet (API)')
      expect(flux[2].at_css('form')['action']).to eq("/admin/recommandations/#{nouvelle.id}")
      expect(choisi(flux[3].at_css('tr'), :solution_id)).to be_nil
      expect(flux[3].at_css('tr').text).not_to include('Choisissez')
      expect(nouvelle.slice(:demarche_id, :visible)).to eq('demarche_id' => aides.id, 'visible' => false)
    end

    it 'garde l’erreur d’un ajout sur la ligne vide' do
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: aides.id, niveau: 'niveau_2' } }

      expect(flux.pluck('target')).to eq(%w[message-recommandations new_recommandation])
      expect(ligne_renvoyee.at_css('.fr-error-text').text).to eq('Choisissez une solution')
      expect(choisi(ligne_renvoyee, :niveau)).to eq('Solution recommandée')
      expect(ligne_renvoyee.text).not_to include('Brouillon')
      expect(flux.first.text.squish).to eq('Recommandation non enregistrée : Choisissez une solution')
    end

    it 'garde la redirection vers la fiche hors de la ligne' do
      patch "/admin/recommandations/#{recommandation.id}", params: { recommandation: { ordre: '3' } }
      expect(response).to redirect_to("/admin/recommandations/#{recommandation.id}/edit")
    end

    it 'supprime la recommandation depuis sa ligne, après confirmation, et retire la ligne de la démarche' do
      get "/admin/demarches/#{aides.id}/edit"
      poubelle = response.parsed_body.at_css("tr#recommandation_#{recommandation.id} button[data-turbo-confirm]")
      formulaire = response.parsed_body.at_css("form##{poubelle['form']}")
      expect([formulaire['action'], formulaire.at_css('input[name=_method]')['value'], formulaire.ancestors('form').size]).to eq(["/admin/recommandations/#{recommandation.id}", 'delete', 0])
      expect([poubelle.text.squish, poubelle['data-turbo-confirm']]).to eq(['Supprimer la recommandation API QF (API)', 'Supprimer la recommandation API QF (API) ?'])
      expect(response.parsed_body.css('tr#new_recommandation button[data-turbo-confirm]')).to be_empty

      delete "/admin/recommandations/#{recommandation.id}", params: { ligne: 1 }, as: :turbo_stream

      expect(flux.map { [it['action'], it['target']] }).to eq([
        ['remove', "recommandation_#{recommandation.id}"], ['remove', "formulaire_recommandation_#{recommandation.id}"],
        ['remove', "suppression_recommandation_#{recommandation.id}"], %w[update message-recommandations]
      ])
      expect(flux.last.at_css('[autofocus][tabindex="-1"]').text.squish).to eq('« Aides → API QF (API) » supprimé.')
      expect(Recommandation.exists?(recommandation.id)).to be(false)
    end

    it 'garde la redirection vers la liste quand on supprime depuis la page de la recommandation' do
      delete "/admin/recommandations/#{recommandation.id}"
      expect(response).to redirect_to('/admin/recommandations')
    end
  end

  describe 'ce que la suppression emporte' do
    let(:aides) { Demarche.create!(nom: 'Aides') }
    let(:bouquet) { Solution.create!(nom: 'Bouquet') }
    let(:api_qf) { Solution.create!(nom: 'API QF', categorie: 'api') }

    before { sign_in admin }

    def confirmation(chemin)
      get chemin
      response.parsed_body.at_css('form[data-turbo-confirm]')['data-turbo-confirm']
    end

    it 'compte les recommandations et intégrations détachées d’une démarche' do
      [api_qf, Solution.create!(nom: 'API Entreprise', categorie: 'api')].each { |solution| Recommandation.create!(demarche: aides, solution:, niveau: :niveau_1) }
      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme', demarches: [aides])
      expect(confirmation("/admin/demarches/#{aides.id}/edit"))
        .to eq('Supprimer « Aides » ? 2 recommandations seront supprimées. 1 intégration en sera détachée.')
    end

    it 'compte les recommandations et intégrations d’une solution, n’annonce rien quand rien ne part' do
      Recommandation.create!(demarche: aides, solution: api_qf, niveau: :niveau_1)
      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme')
      expect(confirmation("/admin/solutions/#{api_qf.id}/edit"))
        .to eq('Supprimer « API QF (API) » ? 1 recommandation sera supprimée. 1 intégration sera supprimée.')
      expect(confirmation("/admin/solutions/#{Solution.create!(nom: 'Seule').id}/edit")).to eq('Supprimer « Seule » ?')
    end

    it 'compte les démarches et solutions détachées d’un vocabulaire et d’un type d’acteur' do
      usager = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager', demarches: [aides], solutions: [bouquet, api_qf])
      communes = TypeActeur.create!(nom: 'Communes', demarches: [aides])
      expect(confirmation("/admin/vocabulaires/#{usager.id}/edit"))
        .to eq('Supprimer « Particuliers » ? 1 démarche en sera détachée. 2 solutions en seront détachées.')
      expect(confirmation("/admin/types_acteurs/#{communes.id}/edit")).to eq('Supprimer « Communes » ? 1 démarche en sera détachée.')
    end

    it 'nomme les solutions qu’une organisation rendrait privées' do
      dinum = Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public', solutions: [bouquet, Solution.create!(nom: 'Démarches simplifiées')])
      expect(confirmation("/admin/organisations/#{dinum.id}/edit"))
        .to eq('Supprimer « DINUM » ? Ces solutions deviendront privées : Bouquet, Démarches simplifiées.')

      patch "/admin/organisations/#{dinum.id}", params: { organisation: { nom: '', public_ou_prive: 'Privé' } }
      expect(response.parsed_body.at_css('form[data-turbo-confirm]')['data-turbo-confirm'])
        .to eq('Supprimer « DINUM » ? Ces solutions deviendront privées : Bouquet, Démarches simplifiées.')
    end
  end

  describe 'dates de création et de modification' do
    let(:saisie) { Time.zone.local(2001, 1, 1) }
    let(:maintenant) { Time.zone.local(2026, 10, 5, 14, 30) }

    before { sign_in admin }

    {
      Demarche => -> { { nom: 'Aides' } },
      Solution => -> { { nom: 'Bouquet' } },
      Recommandation => -> { { demarche_id: Demarche.create!(nom: 'Aides').id, solution_id: Solution.create!(nom: 'API QF', categorie: 'api').id, niveau: 'niveau_1' } }
    }.each do |modele, fabrique|
      context modele.model_name.human do
        let(:chemin) { "/admin/#{modele.model_name.route_key}" }
        let(:cle) { modele.model_name.param_key }
        let(:dates) { modele.column_names & %w[cree_le modifie_le] }
        let(:dates_saisies) { dates.index_with(saisie) }

        it 'date la création à l’enregistrement, sans tenir compte d’une date envoyée' do
          travel_to(maintenant) { post chemin, params: { cle => fabrique.call.merge(dates_saisies) } }
          expect(modele.last.slice(*dates)).to eq(dates.index_with(maintenant))
        end

        it 'date la modification à chaque enregistrement et garde la date de création' do
          ligne = modele.create!(fabrique.call.merge(dates_saisies))
          travel_to(maintenant) { patch "#{chemin}/#{ligne.id}", params: { cle => { visible: '0' } } }
          expect(ligne.reload.slice(*dates)).to eq(dates_saisies.merge('modifie_le' => maintenant))
        end

        it 'ne propose plus les dates à la saisie' do
          get "#{chemin}/new"
          dates.each { |date| expect(response.body).not_to include("#{cle}[#{date}]") }
        end
      end
    end
  end

  describe 'colonnes obligatoires en base' do
    before { sign_in admin }

    it 'refuse un vocabulaire sans catégorie' do
      post '/admin/vocabulaires', params: { vocabulaire: { nom: 'Particuliers', categorie: '' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Catégorie doit être rempli')
    end

    it 'refuse un vocabulaire sans slug, qui ne filtrerait rien sur le site' do
      post '/admin/vocabulaires', params: { vocabulaire: { nom: 'Particuliers', slug: '', categorie: 'usager' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Slug doit être rempli')
    end

    it 'refuse une intégration sans type' do
      bouquet = Solution.create!(nom: 'Bouquet')
      post '/admin/integrations', params: { integration: { integratrice_id: bouquet.id, integree_id: bouquet.id, type_integration: '' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Type d’intégration doit être rempli')
    end

    it 'refuse une intégration d’une solution avec elle-même' do
      bouquet = Solution.create!(nom: 'Bouquet')
      post '/admin/integrations', params: { integration: { integratrice_id: bouquet.id, integree_id: bouquet.id, type_integration: 'consomme' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Une solution ne peut pas s’intégrer elle-même')
    end

    it 'exige un slug dès qu’une fiche est visible, comme l’import le garantissait' do
      post '/admin/demarches', params: { demarche: { nom: 'Aides', visible: '1', slug: '' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Slug doit être rempli')

      post '/admin/solutions', params: { solution: { nom: 'Bouquet', visible: '1', slug: '' } }
      expect(response).to have_http_status(:unprocessable_content)

      post '/admin/solutions', params: { solution: { nom: 'API QF', categorie: 'api', visible: '1', slug: '' } }
      expect(response).to redirect_to("/admin/solutions/#{Solution.last.id}/edit")
    end

    it 'refuse un slug de démarche déjà pris' do
      Demarche.create!(nom: 'Aides', slug: 'aides')
      post '/admin/demarches', params: { demarche: { nom: 'Autre', slug: 'aides' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Slug est déjà utilisé')
    end
  end

  describe 'listes fermées' do
    before { sign_in admin }

    it 'propose les statuts d’intégration en liste et refuse une saisie libre' do
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: Solution.create!(nom: 'API QF'),
        type_integration: 'consomme')

      get "/admin/integrations/#{integration.id}/edit"
      expect(response.body).to include('<select class="fr-select" name="integration[statut]" id="integration_statut">')
      expect(response.body).to include('<option value="✅ en production">✅ en production</option>')

      patch "/admin/integrations/#{integration.id}", params: { integration: { statut: 'en production' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Statut de l’intégration doit être choisi dans la liste')
    end

    it 'propose public ou privé en boutons radio, non renseigné compris' do
      dinum = Organisation.create!(nom: 'DINUM')

      get "/admin/organisations/#{dinum.id}/edit"
      expect(response.body).to include('<input type="radio" value="" checked="checked" name="organisation[public_ou_prive]" id="organisation_public_ou_prive_" />')
      expect(response.body).to include('<input type="radio" value="Privé" name="organisation[public_ou_prive]" id="organisation_public_ou_prive_privé" />')
      expect(response.body).to include('<label class="fr-label" for="organisation_public_ou_prive_privé">Privé</label>')

      patch "/admin/organisations/#{dinum.id}", params: { organisation: { public_ou_prive: 'Public' } }
      expect(dinum.reload.public_ou_prive).to eq('Public')
    end
  end

  describe 'libellés en français' do
    before { sign_in admin }

    def libelles(chemin)
      get "/admin/#{chemin}/new"
      response.parsed_body.css('form[data-controller="formulaire-modifie"] label, form[data-controller="formulaire-modifie"] legend')
        .map { |libelle| libelle.xpath('text()').text.strip }
    end

    it 'nomme les champs avec les mots du Grist et du site' do
      {
        'demarches' => ['Icône du titre', 'Description courte', 'Cadre juridique', 'Mots-clés'],
        'solutions' => ['Catégorie de solution', 'Identifiant data.gouv', 'URL de demande d’accès', 'Légende de l’image',
                        'Type de solution', 'API FranceConnectée', 'Cette solution ne permet pas'],
        'recommandations' => ['Démarche (obligatoire)', 'Type de recommandation (obligatoire)', 'Données utiles disponibles', 'Paramètres à saisir pour récupérer les données',
                              'En quoi cette API ou ce jeu de données est utile'],
        'integrations' => ['Solution (obligatoire)', 'API ou jeu de données (obligatoire)', 'Type d’intégration (obligatoire)', 'Statut de l’intégration'],
        'organisations' => ['Nom long', 'Type d’organisation privée'],
        'types_acteurs' => ['Ce que cela inclut', 'Codes juridiques'],
        'vocabulaires' => ['Catégorie (obligatoire)']
      }.each { |chemin, attendus| expect(libelles(chemin)).to include(*attendus) }
    end

    it 'propose les valeurs des listes en français et n’affiche aucune clé brute' do
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: Solution.create!(nom: 'API QF'),
        type_integration: 'consomme')
      %w[demarches solutions recommandations integrations organisations types_acteurs vocabulaires].each do |chemin|
        get "/admin/#{chemin}/new"
        expect(response.parsed_body.at_css('form[data-controller="formulaire-modifie"]').text).not_to match(/niveau_\d|_cle_en_main|brique_logicielle|type_simplification|consomme|expose/)
      end

      get '/admin/recommandations/new'
      expect(response.parsed_body.css('#recommandation_niveau option').map(&:text))
        .to eq(['', 'Donnée utile (API ou jeu de données)', 'Solution recommandée'])
      get '/admin/solutions/new'
      expect(response.parsed_body.css('#solution_categorie option').map(&:text))
        .to eq(['', 'Brique technique', 'API', 'Jeu de données', 'Portail de consultation', 'Logiciel métier'])
      get '/admin/vocabulaires/new'
      expect(response.parsed_body.css('#vocabulaire_categorie option').map(&:text))
        .to eq(['', 'Usager', 'Type de simplification', 'Catégorie de solution'])
      get "/admin/integrations/#{integration.id}/edit"
      expect(response.parsed_body.at_css('#integration_type_integration option[selected]').text).to eq('Intégrée')
    end

    it 'explique les champs ambigus dans leur libellé' do
      {
        Recommandation => %w[niveau ordre], Solution => %w[uid_datagouv france_connectee slug],
        Demarche => %w[mots_clefs slug], Integration => %w[type_integration]
      }.each do |modele, champs|
        get "/admin/#{modele.model_name.route_key}/new"
        champs.each do |champ|
          aide = response.parsed_body.at_css("label[for=#{modele.model_name.param_key}_#{champ}] .fr-hint-text")
          expect(aide).to be_present, "#{modele}.#{champ}"
        end
      end
      get '/admin/solutions/new'
      expect(response.parsed_body.at_css('#solution_types_solution legend .fr-hint-text')).to be_present
    end

    it 'annonce les champs obligatoires et laisse le serveur signaler ceux qui manquent' do
      {
        'demarches' => %w[demarche_nom], 'solutions' => %w[solution_nom], 'organisations' => %w[organisation_nom],
        'types_acteurs' => %w[type_acteur_nom], 'vocabulaires' => %w[vocabulaire_nom vocabulaire_slug vocabulaire_categorie],
        'recommandations' => %w[recommandation_solution_id recommandation_demarche_id recommandation_niveau],
        'integrations' => %w[integration_integree_id integration_integratrice_id integration_type_integration]
      }.each do |chemin, obligatoires|
        get "/admin/#{chemin}/new"
        formulaire = response.parsed_body.at_css('form[data-controller="formulaire-modifie"]')
        expect(formulaire['novalidate']).not_to be_nil
        expect(formulaire.css('label').select { |libelle| libelle.text.include?('(obligatoire)') }.pluck('for')).to eq(obligatoires)
        expect(formulaire.css('[required]').pluck('id')).to eq(obligatoires)
      end
    end

    it 'dit dans l’aide les règles qui dépendent d’un autre champ' do
      %w[demarche solution].each do |cle|
        get "/admin/#{cle}s/new"
        expect(response.parsed_body.at_css("label[for=#{cle}_slug] .fr-hint-text").text).to include('Obligatoire')
      end
      expect(response.parsed_body.at_css('label[for=solution_categorie] .fr-hint-text').text).to include('restent vides')
    end

    it 'range les champs dans l’ordre des fiches Grist' do
      {
        'demarches' => ['Icône du titre', 'Nom (obligatoire)', 'Slug', 'Description courte', 'Contexte',
                        'Cadre juridique', 'Fournisseurs de services', 'Mots-clés', 'Vocabulaires'],
        'solutions' => ['Nom (obligatoire)', 'Slug', 'Site internet', 'URL de demande d’accès', 'Organisations',
                        'Image principale', 'Légende de l’image', 'Description courte', 'Type de solution',
                        'Catégorie de solution', 'Vocabulaires', 'Fournisseurs de services', 'Cette solution permet',
                        'Cette solution ne permet pas', 'Identifiant data.gouv', 'API FranceConnectée'],
        'recommandations' => ['Solution (obligatoire)', 'URL de demande d’accès pour cette démarche', 'Démarche (obligatoire)',
                              'Type de recommandation (obligatoire)', 'Ordre', 'Données utiles disponibles', 'Paramètres à saisir pour récupérer les données',
                              'En quoi cette API ou ce jeu de données est utile'],
        'integrations' => ['API ou jeu de données (obligatoire)', 'Solution (obligatoire)', 'Type d’intégration (obligatoire)', 'Statut de l’intégration']
      }.each { |chemin, attendus| expect(libelles(chemin) & attendus).to eq(attendus) }
    end
  end

  describe 'erreurs de saisie' do
    before { sign_in admin }

    def message_du_champ(id)
      champ = response.parsed_body.at_css("##{id}")
      expect(champ['aria-invalid']).to eq('true')
      response.parsed_body.at_css("##{champ['aria-describedby']}").text.strip
    end

    it 'signale l’erreur sous le champ concerné, sans l’envelopper façon Rails' do
      post '/admin/demarches', params: { demarche: { nom: '' } }
      expect(response.parsed_body.at_css('.fr-input-group--error #demarche_nom')).to be_present
      expect(message_du_champ('demarche_nom')).to eq('Nom doit être rempli')
      expect(response.body).not_to include('field_with_errors')
      expect(response.parsed_body.at_css('#demarche_slug')['aria-invalid']).to be_nil
    end

    it 'récapitule les erreurs en tête du formulaire, avec un lien vers chaque champ, et y place le focus' do
      post '/admin/demarches', params: { demarche: { nom: '', visible: '1', slug: '' } }
      recapitulatif = response.parsed_body.at_css('form .fr-alert--error')
      expect(recapitulatif.to_h.slice('tabindex', 'autofocus')).to eq('tabindex' => '-1', 'autofocus' => '')
      expect(recapitulatif.at_css('.fr-alert__title').text).to eq('2 erreurs à corriger')
      expect(recapitulatif.css('a').map { |lien| [lien['href'], lien.text] })
        .to eq([['#demarche_nom', 'Nom doit être rempli'], ['#demarche_slug', 'Slug doit être rempli']])
      expect(recapitulatif.css('a').pluck('data-turbo')).to all(eq('false'))
    end

    it 'relie l’erreur d’une association à sa liste et laisse sans lien une erreur d’ensemble' do
      post '/admin/recommandations', params: { recommandation: { demarche_id: '' } }
      expect(response.parsed_body.css('.fr-alert--error a').pluck('href')).to include('#recommandation_demarche_id')

      bouquet = Solution.create!(nom: 'Bouquet')
      post '/admin/integrations', params: { integration: { integratrice_id: bouquet.id, integree_id: bouquet.id, type_integration: 'expose' } }
      recapitulatif = response.parsed_body.at_css('.fr-alert--error')
      expect(recapitulatif.at_css('.fr-alert__title').text).to eq('1 erreur à corriger')
      expect(recapitulatif.at_css('li').text.strip).to eq('Une solution ne peut pas s’intégrer elle-même')
      expect(recapitulatif.at_css('a')).to be_nil
    end

    it 'demande de choisir la démarche et la solution d’une recommandation' do
      post '/admin/recommandations', params: { recommandation: { demarche_id: '', solution_id: '' } }
      expect(response.parsed_body.at_css('.fr-select-group--error #recommandation_demarche_id')).to be_present
      expect(message_du_champ('recommandation_demarche_id')).to eq('Choisissez une démarche')
      expect(message_du_champ('recommandation_solution_id')).to eq('Choisissez une solution')
    end

    it 'explique qu’une solution est déjà recommandée pour la démarche' do
      reco = Recommandation.create!(demarche: Demarche.create!(nom: 'Aides'), solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_1)
      post '/admin/recommandations', params: { recommandation: { demarche_id: reco.demarche_id, solution_id: reco.solution_id } }
      expect(message_du_champ('recommandation_solution_id')).to eq('Cette solution est déjà recommandée pour cette démarche')
    end

    it 'refuse de mettre en avant une solution privée' do
      post '/admin/recommandations', params: { recommandation: { demarche_id: Demarche.create!(nom: 'Aides').id, solution_id: Solution.create!(nom: 'Bouquet').id } }
      expect(message_du_champ('recommandation_solution_id')).to eq('Une solution privée ne peut pas être mise en avant')
    end

    it 'demande de choisir les deux solutions d’une intégration' do
      post '/admin/integrations', params: { integration: { integratrice_id: '', integree_id: '', type_integration: 'expose' } }
      expect(message_du_champ('integration_integratrice_id')).to eq('Choisissez une solution')
      expect(message_du_champ('integration_integree_id')).to eq('Choisissez une API ou un jeu de données')
    end

    it 'explique pourquoi un champ de fiche doit rester vide pour une API' do
      post '/admin/solutions', params: { solution: { nom: 'API QF', categorie: 'api', description_courte: 'Texte' } }
      expect(message_du_champ('solution_description_courte'))
        .to eq('Description courte doit rester vide : une API ou un jeu de données n’a pas de fiche sur le site')
    end
  end

  describe 'slug' do
    it 'laisse vides les slugs non renseignés, sans collision entre fiches' do
      sign_in admin
      { demarches: Demarche, solutions: Solution }.each do |chemin, modele|
        2.times { post "/admin/#{chemin}", params: { modele.model_name.param_key => { nom: 'Aides', slug: '' } } }
        expect(modele.where(slug: nil).count).to eq(2)
      end
    end

    it 'annonce le format attendu sous le champ et garde la saisie refusée' do
      sign_in admin
      get '/admin/solutions/new'
      expect(response.body).to include('Minuscules sans accent, chiffres et tirets, ex. : cantine-scolaire</span>')

      post '/admin/demarches', params: { demarche: { nom: 'Aides', slug: 'Aides publiques' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Slug ne doit contenir que des minuscules sans accent, des chiffres et des tirets')
      expect(response.body).to include('value="Aides publiques"')
    end
  end

  describe 'champs data.gouv' do
    let(:solution) do
      Solution.create!(nom: 'API QF', uid_datagouv: 'abc', datagouv_titre: 'API Quotient familial', datagouv_organisation: 'DINUM',
        datagouv_logo: 'https://static.data.gouv.fr/dinum.png', datagouv_acces: 'Ouvert', datagouv_acces_acteurs_publics: 'Sous habilitation',
        datagouv_organisation_badges: %w[public-service certified])
    end

    before { sign_in admin }

    it 'les affiche en lecture seule, repris de data.gouv.fr' do
      get "/admin/solutions/#{solution.id}/edit"
      expect(response.body).to include('Repris de data.gouv.fr')
      ['API Quotient familial', 'DINUM', 'https://static.data.gouv.fr/dinum.png', 'Ouvert', 'Sous habilitation', 'public-service', 'certified']
        .each { |valeur| expect(response.body).to include(valeur) }
      Solution::DATAGOUV.each { |champ| expect(response.body).not_to include("solution[#{champ}]") }
    end

    it 'ignore une valeur envoyée par le formulaire' do
      patch "/admin/solutions/#{solution.id}", params: { solution: { datagouv_titre: 'Autre titre', datagouv_organisation_badges: 'autre' } }
      expect(solution.reload.slice(:datagouv_titre, :datagouv_organisation_badges))
        .to eq('datagouv_titre' => 'API Quotient familial', 'datagouv_organisation_badges' => %w[public-service certified])
    end

    it 'n’affiche pas le bloc pour une solution absente de data.gouv' do
      get "/admin/solutions/#{Solution.create!(nom: 'Bouquet').id}/edit"
      expect(response.body).not_to include('Repris de data.gouv.fr')
    end
  end

  describe 'formulaire solution selon sa catégorie' do
    let(:champs_fiche) { %w[slug site_internet url_demande_acces image legende_image description_courte permet ne_permet_pas] }

    before { sign_in admin }

    def champs_masques(solution)
      get "/admin/solutions/#{solution.id}/edit"
      response.parsed_body.css('form [name^="solution["]').select { |champ| champ.ancestors('.fr-hidden').any? }
        .map { |champ| [champ['name'][/\[(\w+)\]/, 1], champ.key?('disabled')] }
    end

    it 'masque et désactive les champs de fiche d’une API ou d’un jeu de données' do
      %w[api base_de_donnees].each do |categorie|
        expect(champs_masques(Solution.create!(nom: categorie, categorie:))).to match_array(champs_fiche.map { |champ| [champ, true] })
      end
    end

    it 'montre les champs de fiche des autres catégories' do
      [nil, 'brique_logicielle'].each { |categorie| expect(champs_masques(Solution.create!(nom: 'Bouquet', categorie:))).to be_empty }
    end

    it 'laisse visible un champ de fiche déjà rempli, pour qu’on puisse le vider' do
      api = Solution.new(nom: 'API QF', categorie: 'api', description_courte: 'Ancienne description')
      api.save!(validate: false)
      expect(champs_masques(api).map(&:first)).to match_array(champs_fiche - ['description_courte'])
    end

    it 'laisse visible un champ vidé quand l’enregistrement échoue, pour qu’il parte vide la fois suivante' do
      api = Solution.new(nom: 'API QF', categorie: 'api', description_courte: 'Ancienne description')
      api.save!(validate: false)
      patch "/admin/solutions/#{api.id}", params: { solution: { nom: '', description_courte: '' } }
      champ = response.parsed_body.at_css('[name="solution[description_courte]"]')
      expect([champ['disabled'], champ.ancestors('.fr-hidden').any?]).to eq([nil, false])
    end

    it 'marque les champs remplis en base, que la bascule vers API garde visibles même vidés après un refus' do
      brique = Solution.create!(nom: 'Bouquet', categorie: 'brique_logicielle', description_courte: 'Ancienne description')
      patch "/admin/solutions/#{brique.id}", params: { solution: { nom: '', description_courte: '' } }
      expect(response.parsed_body.css('[data-rempli-en-base]').map { |groupe| groupe.at_css('[name^="solution["]')['name'] })
        .to eq(['solution[description_courte]'])
    end

    it 'bascule les champs quand la catégorie change' do
      get '/admin/solutions/new'
      categorie = response.parsed_body.at_css('select[name="solution[categorie]"]')
      expect(categorie.to_h.slice('data-controller', 'data-action')).to eq('data-controller' => 'champs-fiche', 'data-action' => 'champs-fiche#basculer')
      expect(JSON.parse(categorie['data-champs-fiche-hors-fiches-value'])).to eq(Solution::HORS_FICHES)
      expect(response.parsed_body.css('form [data-champ-fiche]').size).to eq(champs_fiche.size)
    end
  end

  describe 'solution privée' do
    before { sign_in admin }

    it 'le signale sur la fiche et dans la liste, comme sur le site' do
      privee = Solution.create!(nom: 'Bouquet')
      publique = Solution.create!(nom: 'Mes Aides', organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])

      expect(colonnes('solutions').to_h { |ligne| ligne.values_at('Nom', 'Privée') }).to eq('Bouquet' => 'Oui', 'Mes Aides' => 'Non')
      get "/admin/solutions/#{privee.id}/edit"
      expect(response.parsed_body.at_css('h1 + .fr-badge').text.strip).to eq('Privée')
      get "/admin/solutions/#{publique.id}/edit"
      expect(response.parsed_body.at_css('h1 + .fr-badge')).to be_nil
    end
  end

  describe 'type de solution' do
    before { sign_in admin }

    def cases_cochees(solution)
      get "/admin/solutions/#{solution.id}/edit"
      response.parsed_body.css('input[type=checkbox][name="solution[types_solution][]"][checked]').pluck('value')
    end

    it 'propose les types de la liste fixe en cases à cocher et enregistre ceux cochés' do
      get '/admin/solutions/new'
      expect(response.parsed_body.css('input[type=checkbox][name="solution[types_solution][]"]').pluck('value'))
        .to eq(Solution::TYPES_SOLUTION)

      solution = Solution.create!(nom: 'Acheteza', types_solution: ['Portail agent'])
      patch "/admin/solutions/#{solution.id}", params: { solution: { types_solution: ['', 'Profil acheteur', "Hub d'échange"] } }
      expect(solution.reload.types_solution).to eq(['Profil acheteur', "Hub d'échange"])
      expect(cases_cochees(solution)).to eq(['Profil acheteur', "Hub d'échange"])

      patch "/admin/solutions/#{solution.id}", params: { solution: { types_solution: [''] } }
      expect(solution.reload.types_solution).to eq([])
    end

    it 'refuse un type hors liste et le signale' do
      solution = Solution.create!(nom: 'Acheteza')
      patch "/admin/solutions/#{solution.id}", params: { solution: { types_solution: ['Logiciel'] } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.at_css('.fr-alert--error a[href="#solution_types_solution"]').text)
        .to eq('Type de solution doit être choisi dans la liste')
      expect(response.parsed_body.at_css('fieldset#solution_types_solution')).to be_present
    end
  end

  describe 'image de solution' do
    it 'attache le fichier envoyé par le formulaire' do
      sign_in admin
      image = Rack::Test::UploadedFile.new(StringIO.new('img'), 'image/png', original_filename: 'swagger.png')
      post '/admin/solutions', params: { solution: { nom: 'Bouquet', image: } }
      expect(response).to redirect_to("/admin/solutions/#{Solution.last.id}/edit")
      expect(Solution.last.image).to be_attached
    end

    def avec_image(**attributs)
      Solution.new(nom: 'Bouquet', **attributs).tap do |solution|
        solution.image.attach(io: StringIO.new('img'), filename: 'bouquet.png', content_type: 'image/png')
        solution.save!(validate: false)
      end
    end

    it 'montre l’image actuelle, décrite par sa légende, et les formats acceptés' do
      sign_in admin
      get "/admin/solutions/#{avec_image(legende_image: 'Écran d’accueil').id}/edit"
      expect(response.parsed_body.at_css('.fr-upload-group img')['alt']).to eq('Écran d’accueil')
      expect(response.parsed_body.at_css('label[for=solution_image] .fr-hint-text').text).to include('Formats acceptés : png, jpg, webp')
      expect(response.parsed_body.at_css('label[for=solution_retirer_image] .fr-hint-text').text).to eq('L’image sera retirée à l’enregistrement.')
      expect(response.parsed_body.at_css('#solution_legende_image').to_h.slice('type', 'value')).to eq('type' => 'text', 'value' => 'Écran d’accueil')
      get "/admin/solutions/#{Solution.create!(nom: 'API QF').id}/edit"
      expect(response.parsed_body.at_css('.fr-upload-group img, input[name="solution[retirer_image]"]')).to be_nil
    end

    it 'retire l’image quand la case est cochée, même sur une API où elle était restée' do
      sign_in admin
      [avec_image, avec_image(categorie: 'api')].each do |solution|
        patch "/admin/solutions/#{solution.id}", params: { solution: { nom: 'Bouquet', retirer_image: '1' } }
        expect(response).to redirect_to("/admin/solutions/#{solution.id}/edit")
        expect(solution.reload.image).not_to be_attached
      end
    end

    it 'refuse un fichier qui n’est pas une image png, jpg ou webp sur une solution masquée' do
      sign_in admin
      solution = Solution.create!(nom: 'Bouquet')
      pdf = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4\n"), 'image/png', original_filename: 'capture.png')

      expect { patch "/admin/solutions/#{solution.id}", params: { solution: { nom: 'Bouquet', image: pdf } } }
        .not_to change(ActiveStorage::Blob, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('doit être une image png, jpg ou webp')
      expect(solution.reload.image).not_to be_attached
    end

    it 'garde l’image si l’enregistrement échoue, case cochée et visible même sur une API' do
      sign_in admin
      [avec_image, avec_image(categorie: 'api')].each do |solution|
        patch "/admin/solutions/#{solution.id}", params: { solution: { nom: '', retirer_image: '1' } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(solution.reload.image).to be_attached
        case_retirer = response.parsed_body.at_css('input[name="solution[retirer_image]"][type=checkbox]')
        expect([case_retirer['checked'], case_retirer['disabled'], case_retirer.ancestors('.fr-hidden').any?]).to eq(['checked', nil, false])
      end
    end
  end

  describe 'image en brouillon d’une solution publiée' do
    let(:solution) { Solution.create!(nom: 'Bouquet', slug: 'bouquet', visible: true) }
    let(:image) { Rack::Test::UploadedFile.new(StringIO.new('img'), 'image/png', original_filename: 'nouvelle.png') }

    before { sign_in admin }

    def image_du_formulaire
      get "/admin/solutions/#{solution.id}/edit"
      response.parsed_body.at_css('.fr-upload-group img')
    end

    it 'garde une image chargée hors du site jusqu’à Publier, et la montre dans le formulaire' do
      patch "/admin/solutions/#{solution.id}", params: { solution: { nom: 'Bouquet', image: } }
      expect(solution.reload.image).not_to be_attached
      expect(image_du_formulaire['src']).to include('nouvelle.png')

      patch "/admin/solutions/#{solution.id}", params: { solution: { visible: '1' } }
      expect(solution.reload.image.filename.to_s).to eq('nouvelle.png')
      expect(solution.brouillon).to be_nil
    end

    it 'réaffiche le formulaire quand la publication d’une nouvelle image est refusée' do
      patch "/admin/solutions/#{solution.id}", params: { solution: { image: } }
      patch "/admin/solutions/#{solution.id}", params: { solution: { nom: '', visible: '1', image: Rack::Test::UploadedFile.new(StringIO.new('img'), 'image/png', original_filename: 'autre.png') } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Nom doit être rempli')
      expect(solution.reload.image).not_to be_attached
    end

    it 'retire l’image à la publication seulement' do
      solution.image.attach(image)
      patch "/admin/solutions/#{solution.id}", params: { solution: { nom: 'Bouquet', retirer_image: '1' } }
      expect(solution.reload.image).to be_attached
      expect(image_du_formulaire).to be_nil

      patch "/admin/solutions/#{solution.id}", params: { solution: { visible: '1' } }
      expect(solution.reload.image).not_to be_attached
    end

    it 'refuse un fichier qui n’est pas une image png, jpg ou webp, sans brouillon ni fichier gardé' do
      pdf = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4\n"), 'image/png', original_filename: 'capture.png')
      patch "/admin/solutions/#{solution.id}", params: { solution: { legende_image: 'Accueil' } }

      expect { patch "/admin/solutions/#{solution.id}", params: { solution: { nom: 'Bouquet renommé', image: pdf } } }
        .not_to change(ActiveStorage::Blob, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('doit être une image png, jpg ou webp')
      expect(response.parsed_body.at_css('#solution_nom')['value']).to eq('Bouquet renommé')
      expect(solution.reload.brouillon.keys).not_to include('image', 'nom')
    end

    it 'jette l’image remplacée dans le brouillon' do
      patch "/admin/solutions/#{solution.id}", params: { solution: { image: } }

      expect { patch "/admin/solutions/#{solution.id}", params: { solution: { image: Rack::Test::UploadedFile.new(StringIO.new('img'), 'image/png', original_filename: 'autre.png') } } }
        .to have_enqueued_job(ActiveStorage::PurgeJob)
      expect(image_du_formulaire['src']).to include('autre.png')
    end

    it 'jette l’image du brouillon avec la solution supprimée' do
      patch "/admin/solutions/#{solution.id}", params: { solution: { image: } }

      expect { delete "/admin/solutions/#{solution.id}" }.to have_enqueued_job(ActiveStorage::PurgeJob)
    end

    it 'jette l’image chargée avec le brouillon abandonné' do
      patch "/admin/solutions/#{solution.id}", params: { solution: { image: } }

      expect { patch "/admin/solutions/#{solution.id}/abandonner_brouillon" }.to have_enqueued_job(ActiveStorage::PurgeJob)
      expect(image_du_formulaire).to be_nil
    end
  end

  describe 'fournisseurs de services' do
    before { sign_in admin }

    it 'nomme les types d’acteurs « Fournisseurs de services », comme la table Grist' do
      fournisseur = TypeActeur.create!(nom: 'Communes')
      get '/admin'
      expect(response.parsed_body.at_css('a[href="/admin/types_acteurs"]').text).to eq('Fournisseurs de services')
      { '/admin/types_acteurs' => 'Fournisseurs de services', '/admin/types_acteurs/new' => 'Fournisseur de services : nouvelle ligne' }.each do |chemin, titre|
        get chemin
        expect(response.parsed_body.at_css('h1').text).to eq(titre)
      end
      get "/admin/types_acteurs/#{fournisseur.id}/edit"
      expect(response.parsed_body.at_css('title').text).to start_with('Communes — Modifier — Fournisseur de services')
    end

    it 'fait cocher ses regroupements parmi les filtres « Démarches gérées par » du site' do
      fournisseur = TypeActeur.create!(nom: 'Communes', slugs: %w[communes])
      get "/admin/types_acteurs/#{fournisseur.id}/edit"
      regroupements = response.parsed_body.at_css('fieldset:has(> legend:contains("Regroupements"))')
      expect(regroupements.at_css('legend .fr-hint-text').text).to include('« Démarches gérées par »')
      cases = regroupements.css('input[type=checkbox]')
      expect(cases.map { |case_a_cocher| regroupements.at_css("label[for=#{case_a_cocher['id']}]").text.strip }).to eq(TypeActeur::FILTRES.keys)
      expect(cases.select { |case_a_cocher| case_a_cocher['checked'] }.pluck('value')).to eq(%w[communes])

      patch "/admin/types_acteurs/#{fournisseur.id}", params: { type_acteur: { slugs: ['', 'tout-acteurs-publics', 'regions'] } }
      expect(fournisseur.reload.slugs).to eq(%w[tout-acteurs-publics regions])
      patch "/admin/types_acteurs/#{fournisseur.id}", params: { type_acteur: { slugs: [''] } }
      expect(fournisseur.reload.slugs).to eq([])
    end

    it 'montre dans la liste les regroupements de chaque fournisseur' do
      TypeActeur.create!(nom: 'Communes', slugs: %w[communes tout-acteurs-publics])
      expect(colonnes('types_acteurs')).to eq([{ 'Nom' => 'Communes', 'Regroupements' => 'Communes et groupements de communes, Tous les acteurs publics' }])
    end

    it 'se consulte avant de se modifier' do
      communes = TypeActeur.create!(nom: 'Communes', slugs: %w[communes tout-acteurs-publics], description: 'Mairies', codes_juridiques: '7210',
        grist_id: 'Fournisseurs_de_services:1', demarches: [Demarche.create!(nom: 'Aides')], solutions: [Solution.create!(nom: 'Bouquet')])
      get "/admin/types_acteurs/#{communes.id}"
      page = response.parsed_body
      expect([page.at_css('h1').text, page.at_css('title').text]).to eq(['Communes', 'Communes — Fournisseur de services | Simplifions.data.gouv.fr'])
      expect(page.css('.fr-breadcrumb__list li').map { |etape| etape.text.strip }).to eq(['Administration', 'Fournisseurs de services', 'Communes'])
      expect(page.css('dt').map { |terme| [terme.text.strip, terme.next_element.text.squish] }).to eq([
        ['Regroupements', 'Communes et groupements de communes, Tous les acteurs publics'], ['Ce que cela inclut', 'Mairies'],
        ['Codes juridiques', '7210'], ['Démarches', 'Aides'], ['Solutions', 'Bouquet'], ['Identifiant Grist', 'Fournisseurs_de_services:1']
      ])
      expect(page.at_css('a.fr-btn:contains("Modifier")')['href']).to eq("/admin/types_acteurs/#{communes.id}/edit")

      communes.update!(description: nil, grist_id: nil)
      get "/admin/types_acteurs/#{communes.id}"
      expect(response.parsed_body.css('dt').find { |terme| terme.text == 'Ce que cela inclut' }.next_element.text.strip).to eq('Non renseigné')
      expect(response.body).not_to include('Identifiant Grist')
    end

    it 'présente la description et les codes juridiques comme des mémos internes' do
      get '/admin/types_acteurs/new'
      %w[description codes_juridiques].each do |champ|
        expect(response.parsed_body.at_css("label[for=type_acteur_#{champ}] .fr-hint-text").text).to eq('Mémo interne, non affiché sur le site')
      end
    end
  end

  describe 'vocabulaires' do
    before { sign_in admin }

    it 'se consultent avant de se modifier' do
      usager = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager',
        demarches: [Demarche.create!(nom: 'Aides')], solutions: [Solution.create!(nom: 'Bouquet')])
      get "/admin/vocabulaires/#{usager.id}"
      page = response.parsed_body
      expect([page.at_css('h1').text, page.at_css('title').text]).to eq(['Particuliers', 'Particuliers — Vocabulaire | Simplifions.data.gouv.fr'])
      expect(page.css('.fr-breadcrumb__list li').map { |etape| etape.text.strip }).to eq(%w[Administration Vocabulaires Particuliers])
      expect(page.css('dt').map { |terme| [terme.text.strip, terme.next_element.text.squish] }).to eq([
        %w[Slug particuliers], %w[Catégorie Usager], %w[Démarches Aides], %w[Solutions Bouquet]
      ])
      expect(page.at_css('a.fr-btn:contains("Modifier")')['href']).to eq("/admin/vocabulaires/#{usager.id}/edit")
    end
  end

  describe 'colonne d’état et d’actions' do
    before { sign_in admin }

    def colonne = response.parsed_body.at_css('aside[aria-labelledby="etat-et-actions"]')

    def boutons_du_formulaire
      identifiant = response.parsed_body.at_css('form[data-controller="formulaire-modifie"]')['id']
      response.parsed_body.css("button[type=submit][form=\"#{identifiant}\"]").map { |bouton| [bouton.text.strip, bouton['name'], bouton['value']] }
    end

    it 'montre l’état, les dates et l’identifiant Grist d’une démarche, et l’enregistre depuis la colonne' do
      demarche = Demarche.create!(nom: 'Aides', grist_id: 'Cas_d_usages:1', cree_le: Time.zone.local(2026, 1, 2), modifie_le: Time.zone.local(2026, 10, 5))
      get "/admin/demarches/#{demarche.id}/edit"

      expect(colonne.text.squish).to include('Masquée', 'Création 02/01/2026', 'Dernière modification 05/10/2026', 'Identifiant Grist : Cas_d_usages:1')
      expect(boutons_du_formulaire).to eq([['Enregistrer', nil, nil], ['Publier', 'demarche[visible]', '1']])
      expect(colonne.at_css('a:contains("Annuler")')['href']).to eq('/admin/demarches')
      expect(response.parsed_body.at_css('form[data-controller="formulaire-modifie"]').css('button:not([type=button]):not([form]), input[name="demarche[visible]"]')).to be_empty
    end

    it 'désigne Enregistrer au script qui le grise tant que rien n’a changé, sans le griser côté serveur' do
      demarche = Demarche.create!(nom: 'Aides')
      get "/admin/demarches/#{demarche.id}/edit"

      expect(colonne.css('button[data-enregistrer]').map { |bouton| [bouton.text.strip, bouton['disabled']] }).to eq([['Enregistrer', nil]])
    end

    it 'publie en enregistrant les autres champs, masque en les gardant en brouillon, et laisse l’état tel quel à l’enregistrement' do
      demarche = Demarche.create!(nom: 'Aides')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }
      expect(demarche.reload.slice(:nom, :visible)).to eq('nom' => 'Aides sociales', 'visible' => false)

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides locales', slug: 'aides', visible: '1' } }
      expect(demarche.reload.slice(:nom, :visible)).to eq('nom' => 'Aides locales', 'visible' => true)
      follow_redirect!
      expect(colonne.text).to include('Publiée')
      expect(boutons_du_formulaire.last).to eq(['Masquer', 'demarche[visible]', '0'])
      expect(colonne.at_css('a:contains("Voir la page publique")')['href']).to eq('/demarches/aides')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides', visible: '0' } }
      expect(demarche.reload.slice(:nom, :visible)).to eq('nom' => 'Aides locales', 'visible' => false)
      expect(demarche.brouillon).to include('nom' => 'Aides')
    end

    it 'propose de publier tant que la démarche en base est masquée, même si la publication a été refusée' do
      demarche = Demarche.create!(nom: 'Aides')
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(colonne.text).to include('Masquée')
      expect(boutons_du_formulaire.map(&:first)).to eq(%w[Enregistrer Publier])
    end

    it 'garde Supprimer dans la colonne, à part du formulaire, et rien d’autre qu’Enregistrer et Publier sur une nouvelle démarche' do
      demarche = Demarche.create!(nom: 'Aides')
      get "/admin/demarches/#{demarche.id}/edit"
      expect(colonne.at_css('form:has(input[name=_method][value=delete])')['action']).to eq("/admin/demarches/#{demarche.id}")

      get '/admin/demarches/new'
      expect(boutons_du_formulaire.map(&:first)).to eq(%w[Enregistrer Publier])
      expect(colonne.text).not_to include('Supprimer', 'Création')
    end

    it 'range les actions de chaque table dans la colonne, Publier seulement pour les solutions et recommandations' do
      travel_to(Time.zone.local(2026, 10, 7))
      bouquet = Solution.create!(nom: 'Bouquet', modifie_le: Time.current)
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      lignes = {
        'solutions' => bouquet,
        'recommandations' => Recommandation.create!(demarche: Demarche.create!(nom: 'Aides'), solution: api_qf, niveau: :niveau_1, modifie_le: Time.current),
        'integrations' => Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme'),
        'organisations' => Organisation.create!(nom: 'DINUM'),
        'types_acteurs' => TypeActeur.create!(nom: 'Communes'),
        'vocabulaires' => Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      }

      lignes.each do |chemin, ligne|
        boutons = ligne.has_attribute?(:visible) ? [['Enregistrer', nil, nil], ['Publier', "#{ligne.model_name.param_key}[visible]", '1']] : [['Enregistrer', nil, nil]]
        get "/admin/#{chemin}/#{ligne.id}/edit"
        expect(boutons_du_formulaire).to eq(boutons), chemin
        expect(colonne.text.squish).to include('Dernière modification 07/10/2026')
        expect(colonne.at_css('a:contains("Annuler")')['href']).to eq("/admin/#{chemin}")
        expect(colonne.at_css("form[action=\"/admin/#{chemin}/#{ligne.id}\"] button").text).to eq('Supprimer')
        expect(response.parsed_body.at_css('form[data-controller="formulaire-modifie"]').css('button[type=submit]')).to be_empty

        get "/admin/#{chemin}/new"
        expect(boutons_du_formulaire).to eq(boutons), chemin
      end
    end
  end

  describe 'brouillon d’une fiche publiée' do
    let!(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }

    before { sign_in admin }

    def colonne = response.parsed_body.at_css('aside[aria-labelledby="etat-et-actions"]')
    def page_publique = get('/demarches/aides').then { response.parsed_body.at_css('h1').text.squish }
    def nom_dans_le_formulaire = get("/admin/demarches/#{demarche.id}/edit").then { response.parsed_body.at_css('#demarche_nom')['value'] }

    def actions
      get "/admin/demarches/#{demarche.id}/edit"
      colonne.css('button').map { |bouton| [bouton.text.strip, bouton['name'], bouton['value']] }
    end

    it 'garde Enregistrer en brouillon hors du site, rouvre le formulaire dessus, et le publie' do
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }
      expect(response).to redirect_to("/admin/demarches/#{demarche.id}/edit")
      follow_redirect!
      expect(response.body).to include('« Aides » : brouillon enregistré, non publié.')
      expect(colonne.text.squish).to include('Publiée', 'Brouillon non publié')
      expect(page_publique).to include('Aides')
      expect(page_publique).not_to include('sociales')
      expect(nom_dans_le_formulaire).to eq('Aides sociales')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales', visible: '1' } }
      expect(page_publique).to include('Aides sociales')
      get "/admin/demarches/#{demarche.id}/edit"
      expect(colonne.text).not_to include('Brouillon')
    end

    it 'date le brouillon à part de la dernière modification, et ne versionne que la publication, au nom de l’admin' do
      demarche.update!(modifie_le: Time.zone.local(2026, 10, 5))
      travel_to(Time.zone.local(2026, 10, 7, 9, 30)) { patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } } }
      get "/admin/demarches/#{demarche.id}/edit"
      expect(colonne.text.squish).to include('Dernière modification 05/10/2026', 'Brouillon du 07/10/2026 à 09:30')
      expect(demarche.versions.count).to eq(1)

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(demarche.versions.last.whodunnit).to eq(admin.id.to_s)
      expect(demarche.versions.last.changeset.keys).to contain_exactly('nom', 'updated_at')
    end

    it 'prévient quand l’import Grist a modifié la fiche depuis le début du brouillon, pas avant' do
      travel_to(Time.zone.local(2026, 10, 7, 8)) { PaperTrail.request(whodunnit: 'Import Grist') { demarche.update!(contexte: 'Avant') } }
      travel_to(Time.zone.local(2026, 10, 7, 9, 30)) { patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } } }
      get "/admin/demarches/#{demarche.id}/edit"
      expect(colonne.at_css('.fr-alert')).to be_nil

      travel_to(Time.zone.local(2026, 10, 7, 10)) { PaperTrail.request(whodunnit: 'Import Grist') { demarche.reload.update!(contexte: 'Après') } }
      travel_to(Time.zone.local(2026, 10, 7, 11)) { patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales et familiales' } } }
      get "/admin/demarches/#{demarche.id}/edit"
      alerte = colonne.at_css('.fr-alert')
      expect(alerte.text.squish).to include('Le Grist a modifié cette fiche le 07/10/2026 à 10:00 : publier remplacera ces changements.')
      expect(alerte.at_css('a')['href']).to eq("/admin/historique/demarches/#{demarche.id}")
    end

    it 'abandonne le brouillon pour revenir au publié' do
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }

      patch "/admin/demarches/#{demarche.id}/abandonner_brouillon"
      expect(response).to redirect_to("/admin/demarches/#{demarche.id}/edit")
      expect(nom_dans_le_formulaire).to eq('Aides')
      expect(colonne.text).not_to include('Brouillon')
    end

    it 'enregistre un brouillon incomplet et en refuse la publication avec l’erreur' do
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: '' } }
      expect(response).to redirect_to("/admin/demarches/#{demarche.id}/edit")

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Nom doit être rempli')
      expect(page_publique).to include('Aides')
    end

    it 'annonce le masquage d’une démarche publiée, sans parler du brouillon gardé' do
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales', visible: '0' } }
      follow_redirect!

      expect(response.body).to include('« Aides » enregistré.')
      expect(colonne.text.squish).to include('Masquée', 'Brouillon non publié')
    end

    it 'écrit directement une démarche masquée' do
      demarche.update!(visible: false)
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }

      expect(demarche.reload.slice(:nom, :brouillon)).to eq('nom' => 'Aides sociales', 'brouillon' => nil)
    end

    it 'propose Publier et Masquer sur une fiche publiée, Abandonner seulement avec un brouillon' do
      expect(actions).to eq([['Enregistrer', nil, nil], ['Publier', 'demarche[visible]', '1'], ['Masquer', 'demarche[visible]', '0'], ['Supprimer', nil, nil]])

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }
      expect(actions.map(&:first)).to eq(['Enregistrer', 'Publier', 'Masquer', 'Abandonner le brouillon', 'Supprimer'])
      expect(colonne.at_css('form:has(button:contains("Abandonner"))')['data-turbo-confirm']).to eq('Abandonner le brouillon de « Aides » ? Les modifications non publiées seront perdues.')
    end
  end

  describe 'recommandations d’une démarche publiée' do
    let!(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let!(:publiee) { Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Mes Aides', categorie: 'api'), niveau: :niveau_2, donnees_utiles: 'Quotient', visible: true) }
    let(:nouvelle) { Recommandation.find_by!(solution: Solution.find_by!(nom: 'Bouquet')) }

    before { sign_in admin }

    def colonne = response.parsed_body.at_css('aside[aria-labelledby="etat-et-actions"]')
    def cartes_publiques = get('/demarches/aides').then { response.parsed_body.css('.reco-card').map { it.text.squish } }

    def ajouter_bouquet
      post '/admin/recommandations', params: { recommandation: { demarche_id: demarche.id, solution_id: Solution.create!(nom: 'Bouquet', categorie: 'api').id, niveau: 'niveau_2' } }
    end

    it 'garde hors du site la modification d’une recommandation publiée et l’ajout d’une nouvelle' do
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { donnees_utiles: 'Revenu fiscal' } }
      ajouter_bouquet

      expect(cartes_publiques.size).to eq(1)
      expect(cartes_publiques.first).to include('Quotient')
      expect(nouvelle.visible).to be(false)
      get "/admin/recommandations/#{publiee.id}/edit"
      expect(response.parsed_body.at_css('#recommandation_donnees_utiles').text.strip).to eq('Revenu fiscal')
    end

    it 'compte les recommandations en brouillon dans la colonne de la démarche et les publie avec elle' do
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { donnees_utiles: 'Revenu fiscal' } }
      ajouter_bouquet
      get "/admin/demarches/#{demarche.id}/edit"
      expect(colonne.text.squish).to include('2 recommandations en brouillon')

      expect { patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides', visible: '1' } } }.to change(PaperTrail::Version, :count).by(2)
      expect(cartes_publiques.map { it[/Mes Aides|Bouquet/] }).to contain_exactly('Mes Aides', 'Bouquet')
      expect(cartes_publiques.join).to include('Revenu fiscal')
      expect(Recommandation.where.not(brouillon: nil)).to be_empty
      get "/admin/demarches/#{demarche.id}/edit"
      expect(colonne.text).not_to include('en brouillon')
    end

    it 'annonce dans sa colonne la recommandation qui paraîtra avec la démarche, la publie seule sur son Publier' do
      ajouter_bouquet
      follow_redirect!
      expect(response.body).to include('« Aides → Bouquet (API) » : brouillon enregistré, non publié.')
      expect(colonne.text.squish).to include('Masquée', 'Brouillon — sera publiée avec la démarche')

      patch "/admin/recommandations/#{nouvelle.id}", params: { recommandation: { niveau: 'niveau_2', visible: '1' } }
      expect(cartes_publiques.size).to eq(2)
      expect(nouvelle.reload.brouillon).to be_nil
    end

    it 'laisse masquée la nouvelle recommandation dont on abandonne le brouillon' do
      ajouter_bouquet

      patch "/admin/recommandations/#{nouvelle.id}/abandonner_brouillon"
      expect(nouvelle.reload.slice(:visible, :brouillon)).to eq('visible' => false, 'brouillon' => nil)
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(cartes_publiques.size).to eq(1)
    end

    it 'laisse masquée la recommandation masquée avec un brouillon quand on publie la démarche' do
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { donnees_utiles: 'Revenu fiscal', visible: '0' } }
      follow_redirect!
      expect(colonne.text.squish).not_to include('sera publiée avec la démarche')
      get "/admin/demarches/#{demarche.id}/edit"
      expect(colonne.text).not_to include('en brouillon')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(publiee.reload.visible).to be(false)
      expect(cartes_publiques).to be_empty
    end

    it 'ne publie rien et nomme la recommandation refusée' do
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { niveau: '' } }
      ajouter_bouquet

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales', visible: '1' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('La recommandation « Mes Aides (API) » ne peut pas être publiée : Type de recommandation doit être rempli')
      expect([demarche.reload.nom, nouvelle.visible, publiee.reload.niveau]).to eq(['Aides', false, 'niveau_2'])
    end
  end

  describe 'prévisualisation d’une fiche avec son brouillon' do
    let!(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let(:solution) { Solution.create!(nom: 'Bouquet', slug: 'bouquet', visible: true) }

    def lien_previsualiser(chemin)
      get "/admin/#{chemin}/edit"
      response.parsed_body.at_css('aside[aria-labelledby="etat-et-actions"] a:contains("Prévisualiser")')
    end

    def bandeau = response.parsed_body.at_css('.fr-notice')

    it 'ouvre la page publique avec le brouillon, sous un bandeau, sans changer le site' do
      sign_in admin
      expect(lien_previsualiser("demarches/#{demarche.id}")).to be_nil
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }

      lien = lien_previsualiser("demarches/#{demarche.id}")
      expect([lien['href'], lien['target']]).to eq(["/admin/demarches/#{demarche.id}/previsualisation", '_blank'])
      get lien['href']
      expect(response.parsed_body.at_css('h1').text.squish).to eq('Aides sociales')
      expect(bandeau.text.squish).to include('Prévisualisation', 'non publiée', 'recommandations et les intégrations y paraissent dans leur version publiée')
      expect(response.headers['X-Robots-Tag']).to eq('noindex')
      expect(response.parsed_body.at_css('title').text).to start_with('Prévisualisation - Cas').and include('Aides sociales')

      get '/demarches/aides'
      expect([response.parsed_body.at_css('h1').text.squish, bandeau]).to eq(['Aides', nil])
      expect(demarche.reload.nom).to eq('Aides')
    end

    it 'montre l’image du brouillon d’une solution' do
      sign_in admin
      image = Rack::Test::UploadedFile.new(StringIO.new('img'), 'image/png', original_filename: 'nouvelle.png')
      patch "/admin/solutions/#{solution.id}", params: { solution: { nom: 'Bouquet malin', image: } }

      get lien_previsualiser("solutions/#{solution.id}")['href']
      expect(response.parsed_body.at_css('h1').text.squish).to eq('Bouquet malin')
      expect(response.parsed_body.at_css('.fr-content-media img')['src']).to include('nouvelle.png')
      expect(solution.reload.image).not_to be_attached
    end

    it 'est réservée aux admins connectés' do
      get "/admin/demarches/#{demarche.id}/previsualisation"
      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  describe 'colonnes tableau' do
    it 'affiche et enregistre les mots-clefs une valeur par ligne' do
      sign_in admin
      demarche = Demarche.create!(nom: 'Aides', mots_clefs: %w[aides subventions])

      get "/admin/demarches/#{demarche.id}/edit"
      expect(response.body).to include("<textarea class=\"fr-input\" rows=\"6\" name=\"demarche[mots_clefs]\" id=\"demarche_mots_clefs\">\naides\nsubventions</textarea>")

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { mots_clefs: "aides\r\nprimes" } }
      expect(demarche.reload.mots_clefs).to eq(%w[aides primes])
    end
  end

  describe 'onglets de la fiche' do
    before { sign_in admin }

    def onglets = response.parsed_body.css('[role=tablist] [role=tab]').map { |onglet| [onglet.text.squish, onglet['type'], onglet['aria-selected']] }

    def panneau(libelle)
      onglet = response.parsed_body.css('[role=tab]').find { |bouton| bouton.text.squish.start_with?(libelle) }
      response.parsed_body.at_css("form#formulaire-fiche ##{onglet['aria-controls']}[role=tabpanel]")
    end

    it 'range la démarche en quatre onglets d’un seul formulaire, la fiche ouverte' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      demarche = Demarche.create!(nom: 'Aides')
      Recommandation.create!(demarche:, solution: api, niveau: :niveau_1)
      demarche.integrations << Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api, type_integration: 'consomme')

      get "/admin/demarches/#{demarche.id}/edit"

      expect(onglets).to eq([['Fiche', 'button', 'true'], ['Intégrations (1)', 'button', 'false'], ['Recommandations (1)', 'button', 'false'], ['Historique', 'button', 'false']])
      expect(panneau('Fiche').at_css('input[name="demarche[nom]"]')).to be_present
      expect(panneau('Intégrations').css('input[name="demarche[integration_ids][]"][checked]').size).to eq(1)
      expect(panneau('Recommandations').css('a').map(&:text)).to eq(['Modifier la recommandation API QF (API)', 'Ajouter une recommandation'])
      expect(panneau('Historique').text).to include('Création')
      get '/admin/demarches/new'
      expect(response.parsed_body.at_css('[role=tablist]')).to be_nil
    end

    def liens_par_titre(libelle)
      panneau(libelle).css('h2').to_h { |titre| [titre.text, titre.next_element.css('a').map { |lien| [lien.text, lien['href']] }] }
    end

    it 'range la solution en onglets : ce qu’elle intègre, qui l’intègre, les démarches qui la recommandent, en lecture avec un lien' do
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      bouquet = Solution.create!(nom: 'Bouquet', categorie: 'brique_logicielle')
      aides = Demarche.create!(nom: 'Aides')
      Recommandation.create!(demarche: aides, solution: api_qf, niveau: :niveau_1)
      %w[consomme expose].each { |type_integration| Integration.create!(integratrice: bouquet, integree: api_qf, type_integration:) }

      get "/admin/solutions/#{api_qf.id}/edit"
      expect(onglets).to eq([['Fiche', 'button', 'true'], ['Intégrations (1)', 'button', 'false'], ['Recommandée dans (1)', 'button', 'false'], ['Historique', 'button', 'false']])
      expect(panneau('Fiche').at_css('input[name="solution[nom]"]')).to be_present
      expect(liens_par_titre('Intégrations')).to eq('Solutions qui l’intègrent' => [['Bouquet (Brique technique)', "/admin/solutions/#{bouquet.id}/edit"]], 'Ce qu’elle intègre' => [])
      expect(panneau('Recommandée dans').css('a').map { |lien| [lien.text, lien['href']] }).to eq([['Aides', "/admin/demarches/#{aides.id}/edit"]])
      expect(panneau('Historique').text).to include('Création')

      get "/admin/solutions/#{bouquet.id}/edit"
      expect(liens_par_titre('Intégrations')).to eq('Solutions qui l’intègrent' => [], 'Ce qu’elle intègre' => [['API QF (API)', "/admin/solutions/#{api_qf.id}/edit"]])
      expect(panneau('Intégrations').at_css('a:contains("Ajouter une intégration")')['href']).to eq("/admin/integrations/new?integratrice_id=#{bouquet.id}")
      expect(panneau('Recommandée dans').text.squish).to eq('Aucune démarche ne la recommande.')
    end

    def onglet_ouvert = response.parsed_body.at_css('[role=tab][aria-selected=true]').text.squish

    it 'rouvre après l’enregistrement l’onglet où l’on était, et la fiche pour un onglet inconnu' do
      demarche = Demarche.create!(nom: 'Aides')
      get "/admin/demarches/#{demarche.id}/edit"
      expect(response.parsed_body.at_css('#formulaire-fiche input[type=hidden][name=onglet]')['value']).to eq('fiche')

      patch "/admin/demarches/#{demarche.id}", params: { onglet: 'recommandations', demarche: { nom: 'Aides sociales' } }
      expect(response).to redirect_to("/admin/demarches/#{demarche.id}/edit?onglet=recommandations")
      follow_redirect!
      expect(onglet_ouvert).to eq('Recommandations (0)')
      expect(response.parsed_body.at_css('input[name=onglet]')['value']).to eq('recommandations')

      get "/admin/demarches/#{demarche.id}/edit", params: { onglet: 'inconnu' }
      expect(onglet_ouvert).to eq('Fiche')
    end

    it 'ouvre sur une saisie refusée l’onglet de la première erreur' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      fraude = Demarche.create!(nom: 'Fraude')
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api, type_integration: 'consomme')

      patch "/admin/demarches/#{fraude.id}", params: { onglet: 'historique', demarche: { integration_ids: [integration.id] } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(onglet_ouvert).to eq('Intégrations (0)')

      patch "/admin/demarches/#{fraude.id}", params: { onglet: 'integrations', demarche: { nom: '', integration_ids: [integration.id] } }
      expect(onglet_ouvert).to eq('Fiche')
    end

    it 'pré-remplit l’intégratrice d’une nouvelle intégration' do
      bouquet = Solution.create!(nom: 'Bouquet')
      get '/admin/integrations/new', params: { integratrice_id: bouquet.id }
      expect(response.parsed_body.at_css('#integration_integratrice_id option[selected]').text).to eq('Bouquet')
    end
  end
end
