require 'rails_helper'

RSpec.shared_examples 'un CRUD brut' do |modele, chemin|
  let(:cle) { modele.model_name.param_key }
  let(:modification) { { nom: 'Nouveau nom' } }
  let(:nouveaux) { attributs }
  let(:invalide) { [{ nom: '' }, 'Nom doit être rempli'] }
  let!(:ligne) { modele.create!(attributs) }
  let(:nom) { attributs[:nom] }
  let(:nom_cree) { nom }
  let(:message_cree) { "« #{nom_cree} » enregistré." }
  let(:nom_liste) { nom }
  let(:fiche) { ->(id) { "/admin/#{chemin}/#{id}/edit" } }
  let(:liens_de_la_liste) { 'tbody a' }

  def fil_d_ariane = response.parsed_body.css('.fr-breadcrumb__list li').map { |etape| etape.text.strip }

  it 'exige la connexion' do
    get "/admin/#{chemin}"
    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'liste les lignes avec un lien vers leur fiche' do
    sign_in admin
    get "/admin/#{chemin}"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("#{liens_de_la_liste}[href=\"#{fiche.call(ligne.id)}\"]").text.squish).to start_with(nom_liste)
    expect(response.body).not_to include('Supprimer')
    expect(response.parsed_body.css(liens_de_la_liste).map(&:text)).not_to include('Modifier')
  end

  it 'filtre la liste sur le nom, sans tenir compte des accents ni de la casse' do
    sign_in admin
    get "/admin/#{chemin}", params: { q: I18n.transliterate(nom.split.first).upcase }
    expect(response.body).to include("href=\"#{fiche.call(ligne.id)}")
    expect(response.parsed_body.at_css('input[name=q]')['value']).to eq(I18n.transliterate(nom.split.first).upcase)
    get "/admin/#{chemin}", params: { q: 'introuvable' }
    expect(response.body).not_to include("href=\"#{fiche.call(ligne.id)}")
  end

  it 'dit qu’une recherche ne trouve rien et propose de l’effacer' do
    sign_in admin
    get "/admin/#{chemin}", params: { q: 'introuvable' }
    page = response.parsed_body
    expect(page.at_css('[role=status]').text.squish).to eq("#{aucun} ne contient « introuvable ».")
    expect(page.at_css('table')).to be_nil
    expect(page.css('a').find { |lien| lien.text == 'Effacer la recherche' }['href']).to eq("/admin/#{chemin}")
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
    expect(response.body).to include(message_cree)
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
    let(:liens_de_la_liste) { '.liste-defilante a' }
    let(:aucun) { 'Aucune démarche' }
    let(:collection) { 'Démarches' }
    let(:attributs) { { nom: 'Aides publiques' } }
  end

  it_behaves_like 'un CRUD brut', Solution, 'solutions' do
    let(:liens_de_la_liste) { '.liste-defilante a' }
    let(:aucun) { 'Aucune solution' }
    let(:collection) { 'Solutions' }
    let(:attributs) { { nom: 'Bouquet API Particulier' } }
  end

  it_behaves_like 'un CRUD brut', Recommandation, 'recommandations' do
    let(:aucun) { 'Aucune recommandation' }
    let(:collection) { 'Recommandations' }
    let(:attributs) { { demarche_id: Demarche.create!(nom: 'Aides').id, solution_id: Solution.create!(nom: 'API QF', categorie: 'api').id, niveau: 'niveau_1' } }
    let(:modification) { { ordre: 3 } }
    let(:invalide) { [{ demarche_id: '' }, 'Choisissez une démarche'] }
    let(:nouveaux) { attributs.merge(demarche_id: Demarche.create!(nom: 'Autre démarche').id, niveau: 'niveau_2') }
    let(:nom) { 'Aides → API QF (API)' }
    let(:nom_cree) { 'Autre démarche → API QF (API)' }
    let(:message_cree) { "« #{nom_cree} » : brouillon enregistré, non publié." }
  end

  it_behaves_like 'un CRUD brut', Integration, 'integrations' do
    let(:aucun) { 'Aucune intégration' }
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
    let(:aucun) { 'Aucune organisation' }
    let(:collection) { 'Organisations' }
    let(:attributs) { { nom: 'DINUM' } }
  end

  it_behaves_like 'un CRUD brut', TypeActeur, 'types_acteurs' do
    let(:aucun) { 'Aucun fournisseur de services' }
    let(:collection) { 'Fournisseurs de services' }
    let(:attributs) { { nom: 'Communes' } }
    let(:fiche) { ->(id) { "/admin/types_acteurs/#{id}" } }
  end

  it_behaves_like 'un CRUD brut', Vocabulaire, 'vocabulaires' do
    let(:aucun) { 'Aucun vocabulaire' }
    let(:collection) { 'Vocabulaires' }
    let(:attributs) { { nom: 'Particuliers', slug: 'particuliers', categorie: 'usager' } }
    let(:fiche) { ->(id) { "/admin/vocabulaires/#{id}" } }
  end

  describe 'recherche dans les listes' do
    before { sign_in admin }

    def noms_listes(chemin, recherche)
      get "/admin/#{chemin}", params: { q: recherche }
      return response.parsed_body.css('.liste-defilante .fr-text--bold').map { it.text.strip } if %w[demarches solutions].include?(chemin)

      response.parsed_body.css('tbody tr').map { |ligne| ligne.css('td')[1].text.strip }
    end

    it 'cherche une solution par son nom' do
      ['Impôt particulier', 'Bouquet'].each { |nom| Solution.create!(nom:) }
      expect(noms_listes('solutions', 'impot')).to eq(['Impôt particulier'])
      expect(response.parsed_body.at_css('[role=status]').text.strip).to eq('1 solution')
      noms_listes('solutions', '')
      expect(response.parsed_body.at_css('[role=status]').text.strip).to eq('2 solutions')
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
      Vocabulaire.create!(Array.new(60) { |n| { nom: "Aides #{n}", slug: "aides-#{n}", categorie: 'usager' } } + [{ nom: 'Autre', slug: 'autre', categorie: 'usager' }])

      get '/admin/vocabulaires', params: { q: 'aides' }
      expect(response.parsed_body.css('tbody tr').size).to eq(50)
      expect(response.parsed_body.at_css('.fr-pagination a[title="Page 2"]')['href']).to eq('/admin/vocabulaires?page=2&q=aides')

      get '/admin/vocabulaires', params: { q: 'aides', page: 2 }
      expect(response.parsed_body.css('tbody tr').size).to eq(10)

      get '/admin/vocabulaires', params: { q: 'aides', foo: 'bar', params: { q: 'autre' } }
      expect(response.parsed_body.at_css('.fr-pagination a[title="Page 2"]')['href']).to eq('/admin/vocabulaires?page=2&q=aides')

      get '/admin/vocabulaires', params: { page: ['2'] }
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

    it 'montre si la recommandation est visible, et sa date de modification' do
      aides = Demarche.create!(nom: 'Aides', slug: 'aides', visible: true)
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      Recommandation.create!(demarche: aides, solution: api_qf, niveau: :niveau_1, visible: true, modifie_le: Time.zone.local(2026, 3, 1, 12))

      expect(colonnes('recommandations')).to eq([{ 'Ligne' => 'Aides → API QF (API)', 'Visible' => 'Oui', 'Modifié le' => '01/03/2026' }])
      expect(response.parsed_body.at_css('tbody time')['datetime']).to eq('2026-03-01T12:00:00+01:00')
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
  end

  describe 'brouillons en cours dans les listes' do
    before do
      sign_in admin
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api', visible: true, brouillon: { 'nom' => 'API QF v2' })
      api_sirene = Solution.create!(nom: 'API Sirene', categorie: 'api', visible: true)
      Solution.create!(nom: 'API Urssaf', categorie: 'api')
      Demarche.create!(nom: 'Aides', slug: 'aides', visible: true, brouillon: { 'nom' => 'Aides v2' })
      Demarche.create!(nom: 'Bourses', slug: 'bourses', visible: true)
        .recommandations.create!(solution: api_qf, niveau: :niveau_2, brouillon: { 'visible' => '1' })
      Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true)
        .recommandations.create!(solution: api_sirene, niveau: :niveau_2, visible: true, brouillon: { 'description' => 'Nouveau texte' })
      Demarche.create!(nom: 'Déchets', slug: 'dechets', visible: true)
    end

    def etats(chemin)
      get "/admin/#{chemin}"
      response.parsed_body.css('.liste-defilante a').to_h { [it.at_css('.fr-text--bold').text.strip, it.css('.fr-badge').map(&:text).join(' ')] }
    end

    it 'marque « Brouillon » les démarches avec un brouillon ou une recommandation qui attend leur publication' do
      expect(etats('demarches')).to eq('Aides' => 'Publiée Brouillon', 'Bourses' => 'Publiée Brouillon', 'Cantine' => 'Publiée Brouillon', 'Déchets' => 'Publiée')
    end

    it 'marque « Brouillon » les solutions avec un brouillon' do
      expect(etats('solutions')).to eq('API QF' => 'Publiée Brouillon', 'API Sirene' => 'Publiée', 'API Urssaf' => 'Masquée')
    end

    def noms(chemin, params = {})
      get("/admin/#{chemin}", params:)
      response.parsed_body.css('.liste-defilante .fr-text--bold').map { it.text.strip }
    end

    it 'ne garde que les démarches en brouillon avec le filtre « En brouillon »' do
      expect(noms('demarches', etat: 'brouillons')).to eq(%w[Aides Bourses Cantine])
      expect(noms('demarches', etat: 'brouillons', q: 'bour')).to eq(%w[Bourses])
      expect(noms('demarches', etat: '')).to eq(%w[Aides Bourses Cantine Déchets])
    end

    it 'ne garde que les solutions en brouillon avec le filtre « En brouillon »' do
      expect(noms('solutions', etat: 'brouillons')).to eq(['API QF'])
    end
  end

  describe 'ordre d’une API fournie' do
    before { sign_in admin }

    let(:bouquet) { Solution.create!(nom: 'Bouquet') }
    let(:api_qf) { Solution.create!(nom: 'API QF', categorie: 'api') }

    def rang = response.parsed_body.at_css('#formulaire-fiche [data-rang]')

    it 'se lit sur la page d’une API fournie, sans champ, avec un lien vers le rangement de sa solution' do
      integration = Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'expose', ordre: 2)

      get "/admin/integrations/#{integration.id}/edit"

      expect(response.parsed_body.at_css('[name="integration[ordre]"]')).to be_nil
      expect(rang.text.squish).to eq('Ordre : 2 Ranger les API fournies de Bouquet')
      expect(rang.at_css('a')['href']).to eq("/admin/solutions/#{bouquet.id}/edit?onglet=api-fournies")
    end

    it 'n’est ni lu ni modifiable sur une API intégrée' do
      integration = Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme', ordre: 2)

      get "/admin/integrations/#{integration.id}/edit"
      expect(rang).to be_nil

      patch "/admin/integrations/#{integration.id}", params: { integration: { ordre: '1' } }
      expect(integration.reload.ordre).to eq(2)
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
      get '/admin/solutions'
      expect(response.parsed_body.css('.liste-defilante a').map { it.text.squish }).to eq(['API Impôt particulier API Masquée', 'API Impôt particulier Logiciel métier Masquée'])
      expect(colonnes('recommandations').pluck('Ligne')).to eq(['Aides → API Impôt particulier (API)'])

      get "/admin/solutions/#{api.id}/edit"
      expect(response.parsed_body.at_css('h1').text).to eq('API Impôt particulier (API)')
      expect(response.parsed_body.at_css('.fr-breadcrumb [aria-current]').text.strip).to eq('API Impôt particulier (API)')

      dgfip = Organisation.create!(nom: 'DGFiP', public_ou_prive: 'Public', solutions: [api, fiche])
      get "/admin/organisations/#{dgfip.id}/edit"
      expect(response.parsed_body.at_css('form[data-turbo-confirm]')['data-turbo-confirm'])
        .to end_with('La solution API Impôt particulier (Logiciel métier) deviendra privée.')
    end

    it 'montre en entier une courte liste de cases, sans champ de filtre' do
      api = Solution.create!(nom: 'API Sirene', categorie: 'api')
      5.times { |rang| Recommandation.create!(demarche: Demarche.create!(nom: "Démarche #{rang}"), solution: api, niveau: :niveau_1) }
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Publik Associations'), integree: api, type_integration: 'consomme')

      get "/admin/integrations/#{integration.id}/edit"
      groupe = response.parsed_body.at_css('fieldset:has(> legend:contains("Démarches"))')
      expect(groupe.css('input[type=checkbox]').size).to eq(5)
      expect(groupe.text).not_to include('Filtrer les démarches')
      expect(groupe.css('[data-controller], [data-action], [data-liste-filtrable-target], [aria-live]')).to be_empty
    end

    it 'range chaque longue liste de cases dans un groupe filtrable qui montre tous les choix au clic, sans champ envoyé' do
      11.times do |rang|
        Organisation.create!(nom: "Organisation #{rang}", public_ou_prive: 'Public')
        Solution.create!(nom: "Solution #{rang}")
        Demarche.create!(nom: "Démarche #{rang}")
      end
      10.times { |rang| TypeActeur.create!(nom: "Fournisseur #{rang}") }

      get '/admin/demarches/new'
      courte = response.parsed_body.at_css('fieldset:has(> legend:contains("Fournisseurs de services"))')
      expect(courte.css('input[type=checkbox]').size).to eq(10)
      expect(courte.at_css('input[type=text]')).to be_nil

      {
        'demarches' => [], 'solutions' => ['Organisations'],
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

  describe 'title SEO' do
    before { sign_in admin }

    it 'se saisit sous le nom d’une démarche ou d’une solution, avec son aide' do
      %w[demarche solution].each do |modele|
        get "/admin/#{modele}s/new"
        libelle = response.parsed_body.at_css("label[for=#{modele}_titre_seo]")
        expect(libelle.xpath('text()').text.strip).to eq('Title SEO')
        expect(libelle.at_css('.fr-hint-text').text).to include('moteurs de recherche')
      end
    end

    it 'est publié avec la fiche' do
      demarche = Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true)
      solution = Solution.create!(nom: 'Babily', slug: 'babily', visible: true, categorie: 'brique_logicielle')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { titre_seo: 'Tarif de cantine', visible: '1' } }
      patch "/admin/solutions/#{solution.id}", params: { solution: { titre_seo: 'Logiciel de crèche', visible: '1' } }

      expect(demarche.reload.titre_seo).to eq('Tarif de cantine')
      expect(solution.reload.titre_seo).to eq('Logiciel de crèche')
    end
  end

  describe 'lien vers la page publique' do
    before { sign_in admin }

    def lien_public(chemin)
      get chemin
      response.parsed_body.at_css('a[title^="Voir la page publique"]')
    end

    it 'mène à la page publique d’une démarche ou d’une solution visible, annonce le nouvel onglet' do
      demarche = Demarche.create!(nom: 'Aides', slug: 'aides', visible: true)
      solution = Solution.create!(nom: 'Bouquet', slug: 'bouquet', visible: true)

      lien = lien_public("/admin/demarches/#{demarche.id}/edit")
      expect(lien.to_h.slice('href', 'target', 'title')).to eq('href' => '/demarches/aides', 'target' => '_blank', 'title' => 'Voir la page publique de Aides - nouvelle fenêtre')
      expect(lien_public("/admin/solutions/#{solution.id}/edit")['href']).to eq('/solutions/bouquet')
    end

    it 'affiche l’adresse en ligne d’une démarche publiée, même quand son brouillon la change' do
      demarche = Demarche.create!(nom: 'Aides', slug: 'aides', visible: true)
      demarche.enregistrer('slug' => 'nouvelle')

      lien = lien_public("/admin/demarches/#{demarche.id}/edit")
      expect([lien['href'], lien.text]).to match(['/demarches/aides', a_string_including('/demarches/aides')])
    end

    it 'ne propose aucun lien quand la page publique n’existe pas' do
      expect(lien_public("/admin/demarches/#{Demarche.create!(nom: 'Aides', slug: 'aides').id}/edit")).to be_nil
      expect(lien_public("/admin/solutions/#{Solution.create!(nom: 'API QF', categorie: 'api', visible: true).id}/edit")).to be_nil

      demarche = Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true)
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { slug: 'Mauvais slug', visible: '1' } }
      expect(response.parsed_body.at_css('a[title^="Voir la page publique"]')['href']).to eq('/demarches/cantine')
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

  describe 'solutions recommandées et données utiles dans la fiche démarche' do
    let!(:aides) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let(:page) { response.parsed_body }

    before { sign_in admin }

    def solution(nom) = Solution.create!(nom:, categorie: 'api')
    def fiche = get("/admin/demarches/#{aides.id}/edit").then { page }
    def flux = Nokogiri::HTML5.fragment(response.body).css('turbo-stream')
    def flux_vers(cible) = flux.find { it['target'] == cible }.at_css('template')
    def cartes(dans) = dans.css('li[id^=recommandation_]').map { |carte| carte.css('.carte-recommandee > p:not(.fr-badge), h3, .fr-badge').map { it.text.squish } }
    def donnees(dans) = dans.css('.donnees-disponibles li').map { it.text.squish }
    def carte(dans, recommandation) = dans.at_css("li##{ActionView::RecordIdentifier.dom_id(recommandation)}")
    def orphelines(dans) = dans.at_css('#rattachees-a-aucune-solution')
    def fenetre(dans, recommandation) = dans.at_css("dialog#fenetre-#{ActionView::RecordIdentifier.dom_id(recommandation)}")

    def brique_exposant(nom, *apis)
      Solution.create!(nom:, categorie: 'brique_logicielle', organisations: [Organisation.create!(nom: "Éditeur #{nom}", public_ou_prive: 'Public')]).tap do |brique|
        apis.each { Integration.create!(integratrice: brique, integree: it, type_integration: 'expose') }
      end
    end

    it 'range chaque donnée utile dans la carte de la solution qui la fournit, les autres à part' do
      x = solution('API X')
      y = solution('API Y')
      orpheline = solution('API Seule')
      a = Recommandation.create!(demarche: aides, solution: brique_exposant('Brique A', x, y), niveau: :niveau_2, ordre: 1)
      b = Recommandation.create!(demarche: aides, solution: solution('API B'), niveau: :niveau_2, ordre: 2)
      Recommandation.create!(demarche: aides, solution: x, niveau: :niveau_1, ordre: 1)
      Recommandation.create!(demarche: aides, solution: orpheline, niveau: :niveau_1)
      fiche

      expect(carte(page, a).at_css('h4').text.squish).to eq('Données utiles (1)')
      expect(donnees(carte(page, a))).to eq(['API X (API) Position 1'])
      expect([carte(page, b).css('h4').map { it.text.squish }, donnees(carte(page, b))]).to eq([['Intégrations (0)'], []])
      expect(orphelines(page).at_css('h3').text.squish).to eq('Rattachées à aucune solution recommandée')
      expect(donnees(orphelines(page))).to eq(['API Seule (API) —Sans position'])
      expect(page.css('h2, h3, h4').map { it.text.squish }).not_to include(a_string_starting_with('Données disponibles'))
    end

    it 'n’affiche le bloc des données rattachées à aucune solution que s’il en reste' do
      Recommandation.create!(demarche: aides, solution: solution('API B'), niveau: :niveau_2)
      fiche
      expect(orphelines(page).text.strip).to be_empty
    end

    def ligne_de_donnee(dans, recommandation) = dans.at_css("form##{ActionView::RecordIdentifier.dom_id(recommandation, :donnee_utile)}")
    def choisi(dans, champ) = dans.at_css("[name=\"recommandation[#{champ}]\"]").then { it.name == 'select' ? it.at_css('option[selected]')&.text : it['value'] || it.text.strip }

    it 'montre sous les blocs de texte les solutions recommandées en cartes, avec leur nombre' do
      Recommandation.create!(demarche: aides, solution: solution('Mes Aides'), niveau: :niveau_2, ordre: 2, visible: true)
      Recommandation.create!(demarche: aides, solution: solution('Aides Locales'), niveau: :niveau_2, ordre: 1)
      Recommandation.create!(demarche: aides, solution: solution('Nouvelle Aide'), niveau: :niveau_2, brouillon: { 'visible' => '1' })
      Recommandation.create!(demarche: aides, solution: solution('Aide Rangée'), niveau: :niveau_2, ordre: 9, visible: true, brouillon: { 'ordre' => '3' })
      Recommandation.create!(demarche: aides, solution: solution('API QF'), niveau: :niveau_1, ordre: 1, visible: true)
      Recommandation.create!(demarche: aides, solution: solution('API Impôt'), niveau: :niveau_1, visible: true)
      Recommandation.create!(demarche: Demarche.create!(nom: 'Autre'), solution: solution('Ailleurs'), niveau: :niveau_2)

      fiche
      expect(page.at_css('#formulaire-fiche').css('h2:not(.fr-modal__title)').map { it.text.squish }).to start_with('Contexte', 'Cadre juridique', 'Solutions recommandées (4)')
      expect(cartes(page)).to eq([
        ['Position 1', 'Aides Locales (API)', 'Masquée'], ['Position 2', 'Mes Aides (API)'], ['Position 3', 'Aide Rangée (API)'],
        ['Sans position', 'Nouvelle Aide (API)', 'Ajoutée au brouillon']
      ])
      expect(page.at_css("#recommandation_#{Recommandation.find_by!(ordre: 2).id}").css('button').map { it.text.squish }).to eq(['Modifier Mes Aides (API)', 'Retirer Mes Aides (API)', 'Ajouter une intégration à Mes Aides (API)'])
      expect(donnees(page)).to eq(['API QF (API) Position 1', 'API Impôt (API) —Sans position'])
      expect(page.at_css('button[aria-controls="fenetre-new_recommandation"]').text.squish).to eq('Ajouter une solution recommandée')
      expect(page.css('[role=tab]').map { it.text.squish }).not_to include(a_string_starting_with('Recommandations'))
    end

    it 'ouvre pour chaque carte une fenêtre « Modifier » à son propre formulaire, hors de celui de la fiche, et une fenêtre vide pour ajouter' do
      recommandation = Recommandation.create!(demarche: aides, solution: solution('Mes Aides'), niveau: :niveau_2, ordre: 2, description: 'Aide du mois')
      fiche
      dialogue = fenetre(page, recommandation)
      formulaire = dialogue.at_css('form')

      expect(page.at_css("##{ActionView::RecordIdentifier.dom_id(recommandation, :modifier)}")['aria-controls']).to eq(dialogue['id'])
      expect(dialogue.at_css('h2').text).to eq('Modifier la solution recommandée')
      expect([formulaire['action'], formulaire.at_css('input[name=_method]')['value'], formulaire.ancestors('form').size]).to eq(["/admin/recommandations/#{recommandation.id}", 'patch', 0])
      expect(formulaire.css('select, input:not([type=hidden]), textarea').pluck('name')).to eq(
        %w[solution_id niveau ordre description donnees_utiles parametres_a_saisir url_demande_acces].map { "recommandation[#{it}]" }
      )
      expect([choisi(formulaire, :solution_id), choisi(formulaire, :ordre), choisi(formulaire, :description)]).to eq(['Mes Aides (API)', '2', 'Aide du mois'])
      expect(dialogue.css('.fr-modal__footer button').map { [it.text, it['type'], it['form']] }).to eq([['Annuler', 'reset', formulaire['id']], ['Enregistrer', 'submit', formulaire['id']]])

      vide = page.at_css('dialog#fenetre-new_recommandation')
      expect([vide.at_css('h2').text, choisi(vide, :niveau), choisi(vide, :solution_id), vide.at_css('input[name="recommandation[demarche_id]"]')['value']])
        .to eq(['Ajouter une solution recommandée', 'Solution recommandée', nil, aides.id.to_s])
    end

    it 'enregistre la fenêtre sur place : la carte à jour, en brouillon tant que la démarche publiée n’est pas publiée à nouveau' do
      recommandation = Recommandation.create!(demarche: aides, solution: solution('Mes Aides'), niveau: :niveau_2, ordre: 1, visible: true)
      patch "/admin/recommandations/#{recommandation.id}", params: { ligne: 1, recommandation: { ordre: '3', description: 'Aide du mois' } }

      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(cartes(flux_vers('cartes-recommandees'))).to eq([['Position 3', 'Mes Aides (API)']])
      expect(choisi(fenetre(flux_vers('formulaires-recommandations'), recommandation), :description)).to eq('Aide du mois')
      expect(fenetre(flux_vers('formulaires-recommandations'), recommandation)['data-controller']).to be_nil
      expect(flux_vers('message-recommandations').text.squish).to eq('« Aides → Mes Aides (API) » : brouillon enregistré, non publié.')
      expect(flux_vers('fenetres-des-donnees-utiles').css('[role=status]').text.strip).to be_empty
      expect(recommandation.reload.slice(:ordre, :description)).to eq('ordre' => 1, 'description' => nil)
    end

    it 'rouvre la fenêtre refusée avec l’erreur sous son champ' do
      aides.update!(visible: false)
      recommandation = Recommandation.create!(demarche: aides, solution: solution('Mes Aides'), niveau: :niveau_2)
      patch "/admin/recommandations/#{recommandation.id}", params: { ligne: 1, recommandation: { solution_id: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      dialogue = fenetre(flux_vers('formulaires-recommandations'), recommandation)
      expect(dialogue['data-controller']).to eq('fenetre-rouverte')
      erreur = dialogue.at_css('.fr-messages-group')
      expect(erreur.text.squish).to eq('Choisissez une solution')
      expect(dialogue.at_css('select[name="recommandation[solution_id]"]')['aria-describedby']).to eq(erreur['id'])
      expect(recommandation.reload.solution).to be_present
    end

    it 'ajoute une solution recommandée depuis la fenêtre vide, qui suit le brouillon de la démarche, puis remet une fenêtre vide' do
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: aides.id, solution_id: solution('Mes Aides').id, niveau: 'niveau_2' } }
      nouvelle = Recommandation.last

      expect(cartes(flux_vers('cartes-recommandees'))).to eq([['Sans position', 'Mes Aides (API)', 'Ajoutée au brouillon']])
      expect(fenetre(flux_vers('formulaires-recommandations'), nouvelle).at_css('form')['action']).to eq("/admin/recommandations/#{nouvelle.id}")
      expect(choisi(flux_vers('formulaires-recommandations').at_css('dialog#fenetre-new_recommandation'), :solution_id)).to be_nil
      expect(nouvelle.slice(:demarche_id, :visible)).to eq('demarche_id' => aides.id, 'visible' => false)
    end

    it 'garde l’erreur d’un ajout dans la fenêtre vide, rouverte' do
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: aides.id, niveau: 'niveau_2', ordre: '4' } }

      vide = flux_vers('formulaires-recommandations').at_css('dialog#fenetre-new_recommandation')
      expect([vide['data-controller'], vide.at_css('.fr-messages-group').text.squish, choisi(vide, :ordre)]).to eq(['fenetre-rouverte', 'Choisissez une solution', '4'])
      expect(flux_vers('message-recommandations').text.squish).to eq('Recommandation non enregistrée : Choisissez une solution')
    end

    it 'retire tout de suite la carte d’une démarche masquée, après la même confirmation qu’avant' do
      aides.update!(visible: false)
      recommandation = Recommandation.create!(demarche: aides, solution: solution('Mes Aides'), niveau: :niveau_2, visible: true)
      fiche
      retirer = page.at_css("#recommandation_#{recommandation.id} button[data-turbo-confirm]")
      formulaire = page.at_css("form##{retirer['form']}")
      expect([formulaire['action'], formulaire.at_css('input[name=_method]')['value'], formulaire.ancestors('form').size]).to eq(["/admin/recommandations/#{recommandation.id}", 'delete', 0])
      expect([retirer.text.squish, retirer['data-turbo-confirm']]).to eq(['Retirer Mes Aides (API)', 'Supprimer la recommandation Mes Aides (API) ?'])

      delete "/admin/recommandations/#{recommandation.id}", params: { ligne: 1 }, as: :turbo_stream

      expect(cartes(flux_vers('cartes-recommandees'))).to be_empty
      expect(flux_vers('message-recommandations').text.squish).to eq('« Aides → Mes Aides (API) » supprimé.')
      expect(Recommandation.exists?(recommandation.id)).to be(false)
    end

    it 'range une carte parmi les solutions recommandées, en brouillon sur une démarche publiée' do
      premiere, deuxieme, troisieme = %w[Un Deux Trois].map.with_index(1) { |nom, ordre| Recommandation.create!(demarche: aides, solution: solution(nom), niveau: :niveau_2, ordre:, visible: true) }
      utile = Recommandation.create!(demarche: aides, solution: solution('API QF'), niveau: :niveau_1, ordre: 1, visible: true)

      patch "/admin/recommandations/#{troisieme.id}/position", params: { position: 1 }, as: :turbo_stream

      expect(cartes(flux_vers('cartes-recommandees')).map { it.first(2) }).to eq([['Position 1', 'Trois (API)'], ['Position 2', 'Un (API)'], ['Position 3', 'Deux (API)']])
      expect(flux_vers('message-recommandations').text.squish).to eq('« Aides → Trois (API) » déplacée en position 1.')
      expect([premiere, deuxieme, troisieme, utile].map { it.reload.ordre }).to eq([1, 2, 3, 1])
      expect([premiere, deuxieme, troisieme].map { it.brouillon['ordre'] }).to eq([2, 3, 1])
      expect(utile.brouillon).to be_nil
    end

    it 'ne range aucune carte quand une recommandation voisine est refusée, et le dit' do
      aides.update!(visible: false)
      premiere, deuxieme, troisieme = %w[Un Deux Trois].map.with_index(1) { |nom, ordre| Recommandation.create!(demarche: aides, solution: solution(nom), niveau: :niveau_2, ordre:) }
      deuxieme.solution.update!(categorie: (Solution.categories.keys - Solution::HORS_FICHES).first)

      patch "/admin/recommandations/#{troisieme.id}/position", params: { position: 1 }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(flux_vers('message-recommandations').text.squish).to start_with('Recommandation non déplacée :')
      expect([premiere, deuxieme, troisieme].map { it.reload.ordre }).to eq([1, 2, 3])
    end

    it 'modifie, ajoute et retire les données utiles d’une carte dans sa fenêtre, une ligne à la fois, sans réécrire la carte qui porte son bouton' do
      qf = solution('API QF')
      impot = solution('API Impôt')
      carte_mes_aides = Recommandation.create!(demarche: aides, solution: brique_exposant('Mes Aides', qf, impot), niveau: :niveau_2)
      utile = Recommandation.create!(demarche: aides, solution: qf, niveau: :niveau_1, ordre: 2, description: 'Quotient')
      id = "donnees-utiles-#{ActionView::RecordIdentifier.dom_id(carte_mes_aides)}"
      fiche
      dialogue = page.at_css("dialog#fenetre-#{id}")
      ligne = ligne_de_donnee(dialogue, utile)

      expect(dialogue.css('form fieldset legend').map { it.text.squish }).to eq(['Donnée utile : API QF (API)', 'Ajouter une donnée utile'])
      expect(ligne.css('select, input:not([type=hidden]), textarea').pluck('name')).to eq(%w[solution_id ordre description].map { "recommandation[#{it}]" })
      expect([ligne['action'], ligne.ancestors('form').size, choisi(ligne, :ordre), choisi(ligne, :description)]).to eq(["/admin/recommandations/#{utile.id}", 0, '2', 'Quotient'])
      expect(ligne.css('button').map { it.text.squish }).to eq(['Enregistrer la donnée utile API QF (API)', 'Retirer API QF (API)'])

      patch "/admin/recommandations/#{utile.id}", params: { ligne: 1, fenetre: id, recommandation: { niveau: 'niveau_1', ordre: '1' } }
      expect(donnees(flux_vers("liste-#{id}"))).to eq(['API QF (API) Position 1'])
      expect(flux.pluck('target')).not_to include('cartes-recommandees', 'rattachees-a-aucune-solution')
      expect(flux_vers("message-#{id}").text.squish).to eq('« Aides → API QF (API) » enregistré.')
      expect(flux_vers('message-recommandations').text.strip).to be_empty

      post '/admin/recommandations', params: { ligne: 1, fenetre: id, recommandation: { demarche_id: aides.id, niveau: 'niveau_1', ordre: '5' } }
      vide = flux_vers("lignes-#{id}").css('form').last
      expect([vide.at_css('.fr-messages-group').text.squish, choisi(vide, :ordre)]).to eq(['Choisissez une solution', '5'])
      expect(flux_vers('formulaires-recommandations').at_css('dialog#fenetre-new_recommandation')['data-controller']).to be_nil

      post '/admin/recommandations', params: { ligne: 1, fenetre: id, recommandation: { demarche_id: aides.id, solution_id: impot.id, niveau: 'niveau_1' } }
      expect(donnees(flux_vers("liste-#{id}"))).to eq(['API QF (API) Position 1', 'API Impôt (API) —Sans position'])
      expect(flux_vers("lignes-#{id}").css('legend').map { it.text.squish }).to eq(['Donnée utile : API QF (API)', 'Donnée utile : API Impôt (API)', 'Ajouter une donnée utile'])
      expect(flux.pluck('target')).not_to include('fenetres-des-donnees-utiles')

      retirer = ligne.at_css('button[data-turbo-confirm]')
      delete "/admin/recommandations/#{utile.id}", params: { ligne: 1, retirer['name'] => retirer['value'] }, as: :turbo_stream
      expect(flux_vers("message-#{id}").text.squish).to eq('« Aides → API QF (API) » supprimé.')
      expect(flux_vers('message-recommandations').text.strip).to be_empty
    end

    it 'propose depuis la carte d’ajouter une donnée utile parmi celles que sa solution fournit et que la démarche ne recommande pas encore' do
      x = solution('API X')
      y = solution('API Y')
      solution('API Ailleurs')
      a = Recommandation.create!(demarche: aides, solution: brique_exposant('Brique A', x, y), niveau: :niveau_2, ordre: 1)
      b = Recommandation.create!(demarche: aides, solution: solution('API B'), niveau: :niveau_2, ordre: 2)
      utile = Recommandation.create!(demarche: aides, solution: x, niveau: :niveau_1)
      id = "donnees-utiles-#{ActionView::RecordIdentifier.dom_id(a)}"
      fiche
      dialogue = page.at_css("dialog#fenetre-#{id}")
      vide = dialogue.css('form').last
      options = ->(formulaire) { formulaire.css('select[name="recommandation[solution_id]"] option').map(&:text).compact_blank }

      expect(carte(page, a).at_css("button[aria-controls='fenetre-#{id}']").text.squish).to eq('Ajouter une donnée utile à Brique A (Brique technique)')
      expect(carte(page, b).text).not_to include('Ajouter une donnée utile')
      expect(page.css('dialog[id^="fenetre-donnees-utiles"]').pluck('id')).to eq(["fenetre-#{id}"])
      expect([dialogue.ancestors('form').size, dialogue.ancestors('#cartes-recommandees').size]).to eq([0, 0])
      expect([options.call(vide), options.call(ligne_de_donnee(dialogue, utile))]).to eq([['API Y (API)'], ['API X (API)', 'API Y (API)']])
      expect(page.css('form[id]').pluck('id').tally.select { |_, nombre| nombre > 1 }).to be_empty

      champs = vide.css('input[type=hidden]').to_h { [it['name'], it['value']] }
      post '/admin/recommandations', params: Rack::Utils.parse_nested_query(champs.merge('recommandation[solution_id]' => y.id.to_s).to_query)
      expect(donnees(flux_vers("liste-#{id}"))).to eq(['API X (API) —Sans position', 'API Y (API) —Sans position'])
      expect(flux_vers("message-#{id}").text.squish).to include('API Y (API)')
    end

    it 'remet à jour les fenêtres des données utiles quand une carte change hors de ces fenêtres' do
      api = solution('API QF')
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: aides.id, solution_id: brique_exposant('Mes Aides', api).id, niveau: 'niveau_2' } }
      nouvelle = Recommandation.last
      fenetres = flux_vers('fenetres-des-donnees-utiles')
      expect(fenetres.css('dialog').pluck('id')).to eq(["fenetre-donnees-utiles-#{ActionView::RecordIdentifier.dom_id(nouvelle)}"])
    end

    it 'garde modifiables les données utiles rattachées à aucune solution recommandée, dans leur propre fenêtre' do
      orpheline = Recommandation.create!(demarche: aides, solution: solution('API Seule'), niveau: :niveau_1)
      fiche
      id = 'donnees-utiles-rattachees-a-aucune-solution'
      expect(orphelines(page).at_css("button[aria-controls='fenetre-#{id}']").text.squish).to eq('Modifier les données utiles rattachées à aucune solution')
      expect(page.at_css("dialog#fenetre-#{id}").css('legend').map { it.text.squish }).to eq(['Donnée utile : API Seule (API)'])

      patch "/admin/recommandations/#{orpheline.id}", params: { ligne: 1, fenetre: id, recommandation: { niveau: 'niveau_1', ordre: '3' } }
      expect(donnees(flux_vers("liste-#{id}"))).to eq(['API Seule (API) Position 3'])
      expect(flux.pluck('target')).not_to include('rattachees-a-aucune-solution')
      expect(flux_vers("message-#{id}").text.squish).to eq('« Aides → API Seule (API) » enregistré.')
    end

    it 'pré-remplit la démarche d’une nouvelle recommandation' do
      get '/admin/recommandations/new', params: { demarche_id: aides.id }
      expect(page.at_css('#recommandation_demarche_id option[selected]').text).to eq('Aides')
    end

    it 'garde la démarche et ses autres recommandations sous les yeux pendant l’édition d’une recommandation' do
      aides.update!(description_courte: 'Demander une aide sociale')
      recommandation = Recommandation.create!(demarche: aides, solution: solution('API QF'), niveau: 'niveau_1')
      Recommandation.create!(demarche: aides, solution: solution('Mes Aides'), niveau: 'niveau_2', ordre: 4)

      get "/admin/recommandations/#{recommandation.id}/edit"
      expect(page.css('#tableau-autres-recommandations tbody tr').map { it.css('td').first(3).map { it.text.squish } }).to eq([['Mes Aides (API)', 'Solution recommandée', '4']])
      encart = page.at_css('aside.fr-callout')
      expect(encart.text.squish).to include('Démarche : Aides', 'Demander une aide sociale')
      expect(encart.at_css('a[aria-label="Voir la fiche Aides"]')['href']).to eq("/admin/demarches/#{aides.id}/edit")
    end

    it 'garde la redirection vers la fiche de la recommandation hors de la démarche' do
      recommandation = Recommandation.create!(demarche: aides, solution: solution('API QF'), niveau: :niveau_1)
      patch "/admin/recommandations/#{recommandation.id}", params: { recommandation: { ordre: '3' } }
      expect(response).to redirect_to("/admin/recommandations/#{recommandation.id}/edit")
      delete "/admin/recommandations/#{recommandation.id}"
      expect(response).to redirect_to('/admin/recommandations')
    end
  end

  describe 'intégration enregistrée depuis sa ligne dans la solution' do
    let!(:bouquet) { Solution.create!(nom: 'Bouquet') }
    let!(:api_qf) { Solution.create!(nom: 'API QF', categorie: 'api') }
    let!(:integration) { Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme') }
    let(:onglets) { %w[onglet-api-fournies onglet-api-integrees onglet-integratrices] }

    before { sign_in admin }

    def flux = Nokogiri::HTML5.fragment(response.body).css('turbo-stream')
    def ligne_renvoyee = flux.find { it['action'] == 'replace' }.at_css('template tr')
    def choisi(ligne, champ) = ligne.at_css("[name=\"integration[#{champ}]\"]")&.at_css('option[selected]')&.text

    it 'renvoie la ligne enregistrée, l’autre solution modifiable du côté de la liste' do
      patch "/admin/integrations/#{integration.id}", params: { ligne: 1, liste: 'integrees', integration: { type_integration: 'expose', statut: Integration::STATUT_EN_PRODUCTION } }

      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(flux.pluck('target')).to eq(['message-integrations', "integration_#{integration.id}", *onglets])
      expect([choisi(ligne_renvoyee, :integree_id), choisi(ligne_renvoyee, :statut)]).to eq(['API QF (API)', Integration::STATUT_EN_PRODUCTION])
      expect(ligne_renvoyee.at_css('[name="integration[integratrice_id]"]')).to be_nil
      expect(flux.first.text.squish).to eq('« Bouquet → API QF (API) (intégrée) » enregistré.')
      expect(integration.reload.type_integration).to eq('consomme')
    end

    { 'integrees' => %w[expose consomme], 'fournies' => %w[consomme expose] }.each do |liste, (envoye, attendu)|
      it "donne à une ligne ajoutée dans « #{liste} » le type #{attendu}, même si la requête envoie #{envoye}" do
        post '/admin/integrations', params: { ligne: 1, liste:, integration: { integratrice_id: bouquet.id, integree_id: Solution.create!(nom: 'API Impôt', categorie: 'api').id, type_integration: envoye } }

        expect(Integration.last.type_integration).to eq(attendu)
      end
    end

    it 'garde le type choisi sur une ligne d’une liste inconnue' do
      patch "/admin/integrations/#{integration.id}", params: { ligne: 1, liste: 'inconnue', integration: { type_integration: 'expose' } }
      expect(integration.reload.type_integration).to eq('expose')
    end

    it 'garde le type choisi sur la page de l’intégration' do
      patch "/admin/integrations/#{integration.id}", params: { integration: { type_integration: 'expose' } }
      expect(integration.reload.type_integration).to eq('expose')
    end

    it 'renvoie sur la ligne l’intégration d’une solution avec elle-même, reliée à ses champs' do
      patch "/admin/integrations/#{integration.id}", params: { ligne: 1, liste: 'integratrices', integration: { integratrice_id: api_qf.id } }

      expect(response).to have_http_status(:unprocessable_content)
      erreur = ligne_renvoyee.at_css('.fr-error-text')
      expect(erreur.text).to eq('Une solution ne peut pas s’intégrer elle-même')
      expect(ligne_renvoyee.css('select, button:not([data-turbo-confirm])').pluck('aria-describedby').uniq).to eq([erreur['id']])
      expect(ligne_renvoyee.at_css('button').text.squish).to eq('Enregistrer l’intégration Bouquet → API QF (API) (intégrée)')
      expect(flux.first.text.squish).to eq('Intégration non enregistrée : Une solution ne peut pas s’intégrer elle-même')
      expect(integration.reload.integratrice).to eq(bouquet)
    end

    it 'garde sur une ligne refusée l’avertissement des solutions enregistrées' do
      bouquet.update!(slug: 'bouquet', visible: true)
      patch "/admin/integrations/#{integration.id}", params: { ligne: 1, liste: 'integratrices', integration: { integratrice_id: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(ligne_renvoyee.at_css('button[data-turbo-confirm]')['data-turbo-confirm']).to end_with(I18n.t('admin.suppression.immediate'))
    end

    it 'refuse sur la ligne un changement de solution qui sort une démarche de la règle' do
      aides = Demarche.create!(nom: 'Aides')
      Recommandation.create!(demarche: aides, solution: api_qf, niveau: :niveau_1)
      integration.update!(demarches: [aides])
      patch "/admin/integrations/#{integration.id}", params: { ligne: 1, liste: 'integrees', integration: { integree_id: Solution.create!(nom: 'API Impôt', categorie: 'api').id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(ligne_renvoyee.at_css('.fr-error-text').text).to eq('La démarche « Aides » ne recommande pas l’API ou le jeu de données intégré')
      expect(integration.reload.integree).to eq(api_qf)
    end

    it 'ajoute l’intégration de la ligne vide de son côté, puis remet une ligne vide' do
      post '/admin/integrations', params: { ligne: 1, liste: 'integratrices', integration: { integree_id: api_qf.id, integratrice_id: Solution.create!(nom: 'Mes Aides').id, type_integration: 'expose' } }
      nouvelle = Integration.last

      expect(flux.map { [it['action'], it['target']] }).to eq([
        %w[update message-integrations], %w[before integratrices_integration], %w[append formulaires-integrations], %w[replace integratrices_integration],
        *onglets.map { ['update', it] }
      ])
      expect(choisi(flux[1].at_css('tr'), :integratrice_id)).to eq('Mes Aides')
      expect(flux[2].at_css('form')['action']).to eq("/admin/integrations/#{nouvelle.id}")
      expect(choisi(flux[3].at_css('tr'), :integratrice_id)).to be_nil
      expect(nouvelle.slice(:integree_id, :type_integration)).to eq('integree_id' => api_qf.id, 'type_integration' => 'expose')
    end

    def onglets_renvoyes = flux.select { it['action'] == 'update' && it['target'].start_with?('onglet-') }.to_h { [it['target'], it.text.squish] }

    it 'met à jour les nombres des trois onglets de la solution après un ajout' do
      post '/admin/integrations', params: { ligne: 1, liste: 'integrees', integration: { integratrice_id: bouquet.id, integree_id: Solution.create!(nom: 'API Impôt', categorie: 'api').id, type_integration: 'consomme' } }

      expect(onglets_renvoyes).to eq('onglet-api-fournies' => 'API fournies (0)', 'onglet-api-integrees' => 'API intégrées (2)', 'onglet-integratrices' => 'Solutions qui l’intègrent (0)')
    end

    it 'compte dans « Solutions qui l’intègrent » les intégrations d’une API fournie ajoutée' do
      Integration.create!(integratrice: Solution.create!(nom: 'Mes Aides'), integree: api_qf, type_integration: 'consomme')
      post '/admin/integrations', params: { ligne: 1, liste: 'fournies', integration: { integratrice_id: bouquet.id, integree_id: api_qf.id } }

      expect(onglets_renvoyes).to eq('onglet-api-fournies' => 'API fournies (1)', 'onglet-api-integrees' => 'API intégrées (1)', 'onglet-integratrices' => 'Solutions qui l’intègrent (2)')
    end

    it 'ne met à jour aucun onglet quand la ligne ajoutée n’a pas de solution de son côté' do
      post '/admin/integrations', params: { ligne: 1, liste: 'integrees', integration: { integree_id: api_qf.id, type_integration: 'consomme' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(flux.first.text).to include('Intégration non enregistrée')
      expect(onglets_renvoyes).to be_empty
    end

    it 'garde l’erreur d’un ajout sur la ligne vide de son côté' do
      post '/admin/integrations', params: { ligne: 1, liste: 'fournies', integration: { integratrice_id: bouquet.id, type_integration: 'expose' } }

      expect(flux.pluck('target')).to eq(['message-integrations', 'fournies_integration', *onglets])
      expect(ligne_renvoyee.at_css('.fr-error-text').text).to eq('Choisissez une API ou un jeu de données')
    end

    it 'ne demande le type d’intégration que dans l’onglet Solutions qui l’intègrent' do
      Integration.create!(integratrice: Solution.create!(nom: 'Mes Aides'), integree: bouquet, type_integration: 'expose')
      get "/admin/solutions/#{bouquet.id}/edit"

      par_onglet = %w[api-fournies api-integrees integratrices].index_with do |onglet|
        panneau = response.parsed_body.at_css("#onglet-#{onglet}-panneau")
        [panneau.css('select[name="integration[type_integration]"]').size, panneau.css('th')[1].text.squish]
      end
      expect(par_onglet).to eq('api-fournies' => [0, 'Statut'], 'api-integrees' => [0, 'Statut'], 'integratrices' => [2, 'Type d’intégration (obligatoire) et statut'])
    end

    it 'garde la redirection vers la fiche hors de la ligne' do
      patch "/admin/integrations/#{integration.id}", params: { integration: { statut: Integration::STATUT_EN_PRODUCTION } }
      expect(response).to redirect_to("/admin/integrations/#{integration.id}/edit")
    end

    it 'supprime l’intégration depuis sa ligne et met le focus sur le message' do
      delete "/admin/integrations/#{integration.id}", params: { ligne: 1 }, as: :turbo_stream

      expect(flux.map { [it['action'], it['target']] }).to eq([
        ['remove', "integration_#{integration.id}"], ['remove', "formulaire_integration_#{integration.id}"],
        ['remove', "suppression_integration_#{integration.id}"], ['remove', "deplacement_integration_#{integration.id}"], %w[update message-integrations]
      ])
      expect(flux.last.at_css('[autofocus][tabindex="-1"]').text.squish).to eq('« Bouquet → API QF (API) (intégrée) » supprimé.')
      expect(Integration.exists?(integration.id)).to be(false)
    end

    it 'garde la redirection vers la liste quand on supprime depuis la page de l’intégration' do
      delete "/admin/integrations/#{integration.id}"
      expect(response).to redirect_to('/admin/integrations')
    end
  end

  describe 'rang des API fournies d’une solution' do
    let!(:bouquet) { Solution.create!(nom: 'Bouquet') }
    let!(:fournies) do
      ['API Alpha', 'API Beta', 'API Gamma'].map do |nom|
        Integration.create!(integratrice: bouquet, integree: Solution.create!(nom:, categorie: 'api'), type_integration: 'expose')
      end
    end
    let(:gamma) { fournies.last }

    before { sign_in admin }

    def flux = Nokogiri::HTML5.fragment(response.body).css('turbo-stream')
    def ordre_admin = flux.last.css('template tr').map { it.at_css('select').at_css('option[selected]')&.text }
    def boutons(ligne) = ligne.css('button[name=sens]').map { [it.text.squish, it['value'], it['form']] }

    it 'porte sur chaque API fournie une poignée et les boutons Monter et Descendre, reliés à un formulaire hors de la fiche' do
      Integration.create!(integratrice: bouquet, integree: Solution.create!(nom: 'API Delta', categorie: 'api'), type_integration: 'consomme')
      get "/admin/solutions/#{bouquet.id}/edit"

      ligne = response.parsed_body.at_css("#onglet-api-fournies-panneau tr#integration_#{gamma.id}")
      expect(ligne.at_css('[data-poignee]')).to be_present
      expect(boutons(ligne)).to eq([
        ['Monter l’intégration Bouquet → API Gamma (API) (fournie)', 'monter', "deplacement_integration_#{gamma.id}"],
        ['Descendre l’intégration Bouquet → API Gamma (API) (fournie)', 'descendre', "deplacement_integration_#{gamma.id}"]
      ])
      formulaire = response.parsed_body.at_css("form#deplacement_integration_#{gamma.id}")
      expect([formulaire['action'], formulaire.at_css('input[name=_method]')['value'], formulaire.ancestors('form').size])
        .to eq(["/admin/integrations/#{gamma.id}/position", 'patch', 0])
      expect([response.parsed_body.at_css('tbody#lignes-fournies')['data-controller'], ligne['data-deplacement']]).to eq(['rangement', formulaire['id']])
      expect(formulaire.at_css('button[type=submit][name=position][hidden]')).to be_present
      expect(response.parsed_body.css('#onglet-api-fournies-panneau tr#fournies_integration button[name=sens], #onglet-api-integrees-panneau button[name=sens], #onglet-api-integrees-panneau [data-poignee]')).to be_empty
    end

    it 'monte une API fournie, renvoie la liste rangée et l’annonce, le focus resté sur le bouton' do
      patch "/admin/integrations/#{gamma.id}/position", params: { sens: 'monter' }, as: :turbo_stream

      expect(flux.map { [it['action'], it['target']] }).to eq([%w[update message-integrations], %w[update lignes-fournies]])
      expect(flux.first.text.squish).to eq('« Bouquet → API Gamma (API) (fournie) » déplacée en position 2.')
      expect(ordre_admin).to eq(['API Alpha (API)', 'API Gamma (API)', 'API Beta (API)', nil])
      expect(flux.last.at_css('[autofocus]').text.squish).to start_with('Monter l’intégration Bouquet → API Gamma')
      expect(bouquet.api_fournies_dans_l_ordre.map(&:nom)).to eq(['API Alpha', 'API Gamma', 'API Beta'])
    end

    it 'garde le focus sur Descendre quand la ligne arrive en tête' do
      patch "/admin/integrations/#{fournies.second.id}/position", params: { sens: 'monter' }, as: :turbo_stream

      expect(flux.last.at_css('[autofocus]').text.squish).to start_with('Descendre l’intégration Bouquet → API Beta')
    end

    it 'range à la position donnée par le glisser-déposer' do
      patch "/admin/integrations/#{fournies.first.id}/position", params: { position: '3' }, as: :turbo_stream

      expect(ordre_admin).to eq(['API Beta (API)', 'API Gamma (API)', 'API Alpha (API)', nil])
      expect(flux.last.at_css('[autofocus]')).to be_nil
    end

    it 'revient sur l’onglet API fournies sans JavaScript' do
      patch "/admin/integrations/#{fournies.first.id}/position", params: { sens: 'descendre' }

      expect(response).to redirect_to("/admin/solutions/#{bouquet.id}/edit?onglet=api-fournies")
      expect(bouquet.api_fournies_dans_l_ordre.map(&:nom)).to eq(['API Beta', 'API Alpha', 'API Gamma'])
    end

    it 'refuse de ranger une API intégrée, ordre inchangé' do
      integree = Integration.create!(integratrice: bouquet, integree: Solution.create!(nom: 'API Delta', categorie: 'api'), type_integration: 'consomme')

      patch "/admin/integrations/#{integree.id}/position", params: { position: '1' }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(flux.map { [it['action'], it['target']] }).to eq([%w[update message-integrations]])
      expect(flux.first.text.squish).to eq('Intégration non déplacée : Seule une API ou un jeu de données fourni se range')
      expect(fournies.map { it.reload.ordre }).to eq([nil, nil, nil])
    end
  end

  describe 'fiches sans brouillon' do
    let(:sans_brouillon) { 'Pas de brouillon : « Enregistrer » met en ligne tout de suite.' }
    let(:bouquet) { Solution.create!(nom: 'Bouquet') }
    let(:api_qf) { Solution.create!(nom: 'API QF', categorie: 'api') }
    let(:aides) { Demarche.create!(nom: 'Aides') }

    before { sign_in admin }

    def panneau(chemin)
      get chemin
      response.parsed_body.at_css(ETAT_DE_LA_FICHE).text.squish
    end

    it 'dit dans le panneau qu’« Enregistrer » met en ligne tout de suite' do
      integration = Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme')
      expect(panneau("/admin/integrations/#{integration.id}/edit")).to include(sans_brouillon)
      expect(panneau("/admin/organisations/#{Organisation.create!(nom: 'DINUM').id}/edit")).to include(sans_brouillon)
      expect(panneau("/admin/types_acteurs/#{TypeActeur.create!(nom: 'Communes').id}/edit")).to include(sans_brouillon)
      vocabulaire = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      expect(panneau("/admin/vocabulaires/#{vocabulaire.id}/edit")).to include(sans_brouillon)
    end

    it 'ne change pas le panneau des fiches à brouillon' do
      recommandation = Recommandation.create!(demarche: aides, solution: api_qf, niveau: 'niveau_1')
      expect(panneau("/admin/demarches/#{aides.id}/edit")).not_to include(sans_brouillon)
      expect(panneau("/admin/solutions/#{bouquet.id}/edit")).not_to include(sans_brouillon)
      expect(panneau("/admin/recommandations/#{recommandation.id}/edit")).not_to include(sans_brouillon)
    end

    it 'le dit au-dessus des lignes de chaque onglet d’intégrations d’une solution' do
      get "/admin/solutions/#{bouquet.id}/edit"
      debuts = %w[api-fournies api-integrees integratrices].map do |onglet|
        response.parsed_body.at_css("#onglet-#{onglet}-panneau").text.squish
      end
      expect(debuts).to all(start_with(sans_brouillon))
      expect(debuts.map { it.delete_prefix(sans_brouillon).split.first(2).join(' ') })
        .to eq(['API fournies', 'API intégrées', 'Solutions qui'])
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

    describe 'suppression immédiate, même pendant un brouillon' do
      let(:immediate) { 'La suppression est immédiate, même pendant un brouillon : « Abandonner le brouillon » ne la remet pas.' }

      def poubelle(chemin, ligne)
        get chemin
        ligne_de_la_fiche = ligne.is_a?(Recommandation) ? "form##{ActionView::RecordIdentifier.dom_id(ligne, :donnee_utile)}" : "tr##{ActionView::RecordIdentifier.dom_id(ligne)}"
        response.parsed_body.at_css("#{ligne_de_la_fiche} button[data-turbo-confirm]")['data-turbo-confirm']
      end

      it 'le dit en supprimant une recommandation d’une démarche publiée ou masquée avec un brouillon, pas masquée sans brouillon' do
        recommandation = Recommandation.create!(demarche: aides, solution: api_qf, niveau: :niveau_1)
        expect(poubelle("/admin/demarches/#{aides.id}/edit", recommandation)).to eq('Supprimer la recommandation API QF (API) ?')
        expect(confirmation("/admin/recommandations/#{recommandation.id}/edit")).to eq('Supprimer « Aides → API QF (API) » ?')

        recommandation.update!(brouillon: { 'visible' => '1' })
        expect(poubelle("/admin/demarches/#{aides.id}/edit", recommandation)).to eq("Supprimer la recommandation API QF (API) ? #{immediate}")
        get "/admin/recommandations/#{recommandation.id}/edit"
        expect(response.parsed_body.css('form[data-turbo-confirm]').pluck('data-turbo-confirm')).to include("Supprimer « Aides → API QF (API) » ? #{immediate}")

        recommandation.update!(brouillon: nil)

        aides.update!(slug: 'aides', visible: true)
        expect(poubelle("/admin/demarches/#{aides.id}/edit", recommandation)).to eq("Supprimer la recommandation API QF (API) ? #{immediate}")
        expect(confirmation("/admin/recommandations/#{recommandation.id}/edit")).to eq("Supprimer « Aides → API QF (API) » ? #{immediate}")
      end

      it 'le dit en supprimant une intégration dans les onglets de ses deux solutions dès que l’une est publiée' do
        integration = Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme')
        sans_avertissement = 'Supprimer l’intégration Bouquet → API QF (API) (intégrée) ?'
        expect(poubelle("/admin/solutions/#{bouquet.id}/edit", integration)).to eq(sans_avertissement)
        expect(poubelle("/admin/solutions/#{api_qf.id}/edit", integration)).to eq(sans_avertissement)

        bouquet.update!(slug: 'bouquet', visible: true)
        expect(poubelle("/admin/solutions/#{bouquet.id}/edit", integration)).to eq("#{sans_avertissement} #{immediate}")
        expect(poubelle("/admin/solutions/#{api_qf.id}/edit", integration)).to eq("#{sans_avertissement} #{immediate}")

        bouquet.update!(visible: false)
        api_qf.update!(visible: true)
        expect(poubelle("/admin/solutions/#{bouquet.id}/edit", integration)).to eq("#{sans_avertissement} #{immediate}")
        expect(poubelle("/admin/solutions/#{api_qf.id}/edit", integration)).to eq("#{sans_avertissement} #{immediate}")
      end

      it 'le dit sur la fiche d’une intégration dont une des deux solutions est publiée' do
        integration = Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme')
        expect(confirmation("/admin/integrations/#{integration.id}/edit")).to eq('Supprimer « Bouquet → API QF (API) (intégrée) » ?')

        api_qf.update!(visible: true)
        expect(confirmation("/admin/integrations/#{integration.id}/edit")).to eq('Supprimer « Bouquet → API QF (API) (intégrée) » ? La suppression est immédiate.')
      end
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
      demarche = Demarche.create!(nom: 'Aides', visible: true)
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { slug: '', visible: '1' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Slug doit être rempli')

      solution = Solution.create!(nom: 'Bouquet', visible: true)
      patch "/admin/solutions/#{solution.id}", params: { solution: { slug: '', visible: '1' } }
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
      get '/admin/demarches/new'
      expect(response.parsed_body.at_css('label[for=demarche_slug] .fr-hint-text').text).to include('tiré du nom')
      get '/admin/solutions/new'
      expect(response.parsed_body.at_css('label[for=solution_slug] .fr-hint-text').text).to include('tiré du nom', 'Reste vide pour une API')
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
                              'Type de recommandation (obligatoire)', 'Position', 'Données utiles disponibles', 'Paramètres à saisir pour récupérer les données',
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
    it 'rend vide le slug laissé vide quand la démarche est refusée' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api, type_integration: 'consomme')
      sign_in admin
      post '/admin/demarches', params: { demarche: { nom: 'Aide publique', slug: '', integration_ids: [integration.id] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.at_css('[name="demarche[slug]"]')['value']).to be_blank
    end

    it 'tire du nom le slug laissé vide, avec un suffixe quand une autre fiche l’a déjà' do
      sign_in admin
      post '/admin/demarches', params: { demarche: { nom: 'Aide publique', slug: '' } }
      post '/admin/demarches', params: { demarche: { nom: 'Aide publique', slug: '' } }
      follow_redirect!

      expect(response.body).to include('/demarches/aide-publique-2')
      expect(Demarche.pluck(:slug)).to contain_exactly('aide-publique', 'aide-publique-2')
    end

    it 'rend vide le slug laissé vide quand l’enregistrement est refusé' do
      sign_in admin
      post '/admin/solutions', params: { solution: { nom: 'Bouquet', slug: '', types_solution: ['Inconnu'] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.at_css('[name="solution[slug]"]')['value']).to be_blank
    end

    it 'tire du nom le slug laissé vide d’une solution qui a sa page, pas celui d’une API' do
      sign_in admin
      2.times { post '/admin/solutions', params: { solution: { nom: 'Aide publique', categorie: 'brique_logicielle', slug: '' } } }
      post '/admin/solutions', params: { solution: { nom: 'Aide publique', categorie: 'api', slug: '' } }

      expect(Solution.pluck(:categorie, :slug)).to contain_exactly(
        %w[brique_logicielle aide-publique], %w[brique_logicielle aide-publique-2], ['api', nil]
      )
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

  describe 'reprise de data.gouv.fr à l’enregistrement' do
    let(:melodi) { 'https://www.data.gouv.fr/api/1/dataservices/6661e09c7230a8fc3b1ec229/' }
    let(:rien_repris) { 'Rien n’a été repris de data.gouv.fr pour cet identifiant' }

    before do
      sign_in admin
      stub_request(:get, melodi).to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
        body: { title: 'API Melodi', organization: { name: 'Institut national de la statistique et des études économiques' } }.to_json)
    end

    def fiche_affichee
      follow_redirect!
      response.parsed_body.at_css('main').text.squish
    end

    it 'montre les informations reprises dès la création' do
      post '/admin/solutions', params: { solution: { nom: 'API Melodi', categorie: 'api', uid_datagouv: '6661e09c7230a8fc3b1ec229' } }
      fiche = fiche_affichee
      expect(fiche).to include('Titre : API Melodi', 'Institut national de la statistique et des études économiques')
      expect(fiche).not_to include(rien_repris)
    end

    it 'les reprend quand l’identifiant change, sans rappeler data.gouv.fr s’il ne change pas' do
      api = Solution.create!(nom: 'API Melodi', categorie: 'api', uid_datagouv: 'ancien', datagouv_titre: 'Ancien titre')
      patch "/admin/solutions/#{api.id}", params: { solution: { uid_datagouv: '6661e09c7230a8fc3b1ec229' } }
      expect(fiche_affichee).to include('Titre : API Melodi')

      patch "/admin/solutions/#{api.id}", params: { solution: { nom: 'API Melodi Insee' } }
      expect(WebMock).to have_requested(:get, melodi).once
    end

    it 'les reprend à la publication du brouillon qui change l’identifiant d’une API en ligne' do
      api = Solution.create!(nom: 'API Melodi', categorie: 'api', visible: true, uid_datagouv: 'ancien')
      patch "/admin/solutions/#{api.id}", params: { solution: { uid_datagouv: '6661e09c7230a8fc3b1ec229' } }
      expect(WebMock).not_to have_requested(:get, melodi)

      patch "/admin/solutions/#{api.id}", params: { solution: { visible: '1' } }
      expect(fiche_affichee).to include('Titre : API Melodi')
    end

    it 'enregistre l’API quand data.gouv.fr ne connaît pas l’identifiant ou ne répond pas, et le dit sur la fiche' do
      stub_request(:get, 'https://www.data.gouv.fr/api/1/dataservices/inconnu/').to_return(status: 404)
      stub_request(:get, 'https://www.data.gouv.fr/api/1/dataservices/sans-reponse/').to_timeout

      %w[inconnu sans-reponse].each do |uid|
        post '/admin/solutions', params: { solution: { nom: "API #{uid}", categorie: 'api', uid_datagouv: uid } }
        expect(Solution.find_by(uid_datagouv: uid)).to be_present
        expect(fiche_affichee).to include(rien_repris, 'Nouvel essai chaque nuit')
      end
    end

    it 'refuse un identifiant déjà utilisé sans appeler data.gouv.fr, en nommant la fiche qui l’a' do
      Solution.create!(nom: 'API Données du répertoire Sirene', categorie: 'api', uid_datagouv: '672cf6aece89cb14e31f0fba')
      post '/admin/solutions', params: { solution: { nom: 'API Sirene', categorie: 'api', uid_datagouv: '672cf6aece89cb14e31f0fba' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('déjà celui de « API Données du répertoire Sirene (API) »')
      expect(Solution.where(uid_datagouv: '672cf6aece89cb14e31f0fba').count).to eq(1)
      expect(WebMock).not_to have_requested(:get, /data\.gouv\.fr/)
    end

    it 'refuse aussi un identifiant déjà utilisé dans le brouillon d’une API en ligne' do
      Solution.create!(nom: 'API Données du répertoire Sirene', categorie: 'api', uid_datagouv: '672cf6aece89cb14e31f0fba')
      api = Solution.create!(nom: 'API Melodi', categorie: 'api', visible: true, uid_datagouv: 'melodi')
      patch "/admin/solutions/#{api.id}", params: { solution: { uid_datagouv: '672cf6aece89cb14e31f0fba' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('déjà celui de « API Données du répertoire Sirene (API) »')
      expect(api.reload.brouillon).to be_nil
    end
  end

  describe 'formulaire solution selon sa catégorie' do
    let(:champs_fiche) { %w[slug titre_seo site_internet url_demande_acces image legende_image description_courte permet ne_permet_pas] }

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
        .to eq(['solution[slug]', 'solution[description_courte]'])
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

    it 'le signale sur la fiche, comme sur le site' do
      privee = Solution.create!(nom: 'Bouquet')
      publique = Solution.create!(nom: 'Mes Aides', organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])

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

  describe 'etat_de_la_fiche d’état et d’actions' do
    before { sign_in admin }

    def etat_de_la_fiche = response.parsed_body.at_css(ETAT_DE_LA_FICHE)

    def boutons_du_formulaire
      identifiant = response.parsed_body.at_css('form[data-controller="formulaire-modifie"]')['id']
      response.parsed_body.css("button[type=submit][form=\"#{identifiant}\"]").map { |bouton| [bouton.text.strip, bouton['name'], bouton['value']] }
    end

    it 'montre l’état, les dates et l’identifiant Grist d’une démarche, et l’enregistre depuis son état' do
      demarche = Demarche.create!(nom: 'Aides', grist_id: 'Cas_d_usages:1', cree_le: Time.zone.local(2026, 1, 2), modifie_le: Time.zone.local(2026, 10, 5))
      get "/admin/demarches/#{demarche.id}/edit"

      expect(etat_de_la_fiche.text.squish).to include('Masquée', 'Création 02/01/2026', 'Dernière modification 05/10/2026', 'Identifiant Grist : Cas_d_usages:1')
      expect(etat_de_la_fiche.css('button').map(&:text)).to eq(['Publier'])
      expect(etat_de_la_fiche.at_css('input[name="demarche[visible]"]')['value']).to eq('1')
    end

    it 'désigne Enregistrer au script qui le grise tant que rien n’a changé, sans le griser côté serveur' do
      solution = Solution.create!(nom: 'Bouquet')
      get "/admin/solutions/#{solution.id}/edit"

      expect(etat_de_la_fiche.css('button[data-enregistrer]').map { |bouton| [bouton.text.strip, bouton['disabled']] }).to eq([['Enregistrer', nil]])
    end

    it 'publie en enregistrant les autres champs, masque en les gardant en brouillon, et laisse l’état tel quel à l’enregistrement' do
      demarche = Demarche.create!(nom: 'Aides')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }
      expect(demarche.reload.slice(:nom, :visible)).to eq('nom' => 'Aides sociales', 'visible' => false)

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides locales', slug: 'aides', visible: '1' } }
      expect(demarche.reload.slice(:nom, :visible)).to eq('nom' => 'Aides locales', 'visible' => true)
      follow_redirect!
      expect(etat_de_la_fiche.text).to include('Publiée')
      expect(response.parsed_body.at_css('form:has(button:contains("Masquer la démarche")) input[name="demarche[visible]"]')['value']).to eq('0')
      expect(response.parsed_body.at_css('a[title^="Voir la page publique"]')['href']).to eq('/demarches/aides')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides', visible: '0' } }
      expect(demarche.reload.slice(:nom, :visible)).to eq('nom' => 'Aides locales', 'visible' => false)
      expect(demarche.brouillon).to include('nom' => 'Aides')
    end

    it 'propose de publier tant que la démarche en base est masquée, même si la publication a été refusée' do
      demarche = Demarche.create!(nom: 'Aides')
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1', slug: 'Hors format' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(etat_de_la_fiche.text).to include('Masquée')
      expect(etat_de_la_fiche.css('button').map(&:text)).to eq(['Publier'])
    end

    it 'garde Supprimer avec l’état de la fiche, à part du formulaire, et rien d’autre qu’Enregistrer et Publier sur une nouvelle démarche' do
      demarche = Demarche.create!(nom: 'Aides')
      get "/admin/demarches/#{demarche.id}/edit"
      expect(response.parsed_body.css('main form:has(input[name=_method][value=delete])').pluck('action')).to eq(["/admin/demarches/#{demarche.id}"])
      expect(response.parsed_body.at_css('#formulaire-fiche form')).to be_nil

      get '/admin/demarches/new'
      expect(boutons_du_formulaire.map(&:first)).to eq(%w[Enregistrer Publier])
      expect(etat_de_la_fiche.text).not_to include('Supprimer', 'Création')
    end

    it 'range les actions de chaque table avec l’état de la fiche, Publier seulement pour les solutions et recommandations' do
      travel_to(Time.zone.local(2026, 10, 7))
      bouquet = Solution.create!(nom: 'Bouquet', modifie_le: Time.current)
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      lignes = {
        'solutions' => bouquet,
        'recommandations' => Recommandation.create!(demarche: Demarche.create!(nom: 'Aides'), solution: api_qf, niveau: :niveau_2, modifie_le: Time.current),
        'integrations' => Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme'),
        'organisations' => Organisation.create!(nom: 'DINUM'),
        'types_acteurs' => TypeActeur.create!(nom: 'Communes'),
        'vocabulaires' => Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      }

      lignes.each do |chemin, ligne|
        boutons = ligne.has_attribute?(:visible) ? [['Enregistrer', nil, nil], ['Publier', "#{ligne.model_name.param_key}[visible]", '1']] : [['Enregistrer', nil, nil]]
        get "/admin/#{chemin}/#{ligne.id}/edit"
        expect(boutons_du_formulaire).to eq(boutons), chemin
        expect(etat_de_la_fiche.text.squish).to include('Dernière modification 07/10/2026')
        expect(etat_de_la_fiche.at_css('a:contains("Annuler")')['href']).to eq("/admin/#{chemin}")
        expect(etat_de_la_fiche.at_css("form[action=\"/admin/#{chemin}/#{ligne.id}\"] button").text).to eq('Supprimer')
        expect(response.parsed_body.at_css('form[data-controller="formulaire-modifie"]').css('button[type=submit]:not([form])')).to be_empty

        get "/admin/#{chemin}/new"
        expect(boutons_du_formulaire).to eq(boutons), chemin
      end
    end
  end

  describe 'brouillon d’une fiche publiée' do
    let!(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }

    before { sign_in admin }

    def etat_de_la_fiche = response.parsed_body.at_css(ETAT_DE_LA_FICHE)
    def page_publique = get('/demarches/aides').then { response.parsed_body.at_css('h1').text.squish }
    def nom_dans_le_formulaire = get("/admin/demarches/#{demarche.id}/edit").then { response.parsed_body.at_css('#demarche_nom')['value'] }

    def actions
      get "/admin/demarches/#{demarche.id}/edit"
      response.parsed_body.css('main form.button_to button').map { it.text.strip }
    end

    it 'garde Enregistrer en brouillon hors du site, rouvre le formulaire dessus, et le publie' do
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }
      expect(response).to redirect_to("/admin/demarches/#{demarche.id}/edit")
      follow_redirect!
      expect(response.body).to include('« Aides » : brouillon enregistré, non publié.')
      expect(etat_de_la_fiche.text.squish).to include('Publiée', 'Brouillon non publié')
      expect(page_publique).to include('Aides')
      expect(page_publique).not_to include('sociales')
      expect(nom_dans_le_formulaire).to eq('Aides sociales')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales', visible: '1' } }
      expect(page_publique).to include('Aides sociales')
      get "/admin/demarches/#{demarche.id}/edit"
      expect(etat_de_la_fiche.text).not_to include('Brouillon')
    end

    it 'date le brouillon à part de la dernière modification, et versionne le brouillon puis la publication, au nom de l’admin' do
      demarche.update!(modifie_le: Time.zone.local(2026, 10, 5))
      travel_to(Time.zone.local(2026, 10, 7, 9, 30)) { patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } } }
      get "/admin/demarches/#{demarche.id}/edit"
      expect(etat_de_la_fiche.text.squish).to include('Dernière modification 05/10/2026', 'Brouillon du 07/10/2026 à 09:30')
      expect(demarche.versions.pluck(:event)).to contain_exactly('create', 'brouillon')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(demarche.versions.last.whodunnit).to eq(admin.id.to_s)
      expect(demarche.versions.last.changeset.keys).to contain_exactly('nom', 'updated_at')
    end

    it 'prévient quand l’import Grist a modifié la fiche depuis le début du brouillon, pas avant' do
      travel_to(Time.zone.local(2026, 10, 7, 8)) { PaperTrail.request(whodunnit: 'Import Grist') { demarche.update!(contexte: 'Avant') } }
      travel_to(Time.zone.local(2026, 10, 7, 9, 30)) { patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } } }
      get "/admin/demarches/#{demarche.id}/edit"
      expect(etat_de_la_fiche.at_css('.fr-alert')).to be_nil

      travel_to(Time.zone.local(2026, 10, 7, 10)) { PaperTrail.request(whodunnit: 'Import Grist') { demarche.reload.update!(contexte: 'Après') } }
      travel_to(Time.zone.local(2026, 10, 7, 11)) { patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales et familiales' } } }
      get "/admin/demarches/#{demarche.id}/edit"
      alerte = etat_de_la_fiche.at_css('.fr-alert')
      expect(alerte.text.squish).to include('Le Grist a modifié cette fiche le 07/10/2026 à 10:00 : publier remplacera ces changements.')
      expect(alerte.at_css('a')['href']).to eq("/admin/historique/demarches/#{demarche.id}")
    end

    it 'abandonne le brouillon pour revenir au publié' do
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }

      patch "/admin/demarches/#{demarche.id}/abandonner_brouillon"
      expect(response).to redirect_to("/admin/demarches/#{demarche.id}/edit")
      expect(nom_dans_le_formulaire).to eq('Aides')
      expect(etat_de_la_fiche.text).not_to include('Brouillon')
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
      expect(etat_de_la_fiche.text.squish).to include('Masquée', 'Brouillon non publié')
    end

    it 'écrit directement une démarche masquée' do
      demarche.update!(visible: false)
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }

      expect(demarche.reload.slice(:nom, :brouillon)).to eq('nom' => 'Aides sociales', 'brouillon' => nil)
    end

    it 'propose Publier et Masquer sur une fiche publiée, Abandonner seulement avec un brouillon' do
      expect(actions).to eq(['Publier', 'Masquer la démarche', 'Supprimer la démarche'])

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }
      expect(actions).to eq(['Publier ce changement', 'Abandonner le brouillon', 'Masquer la démarche', 'Supprimer la démarche'])
      expect(etat_de_la_fiche.at_css('form:has(button:contains("Abandonner"))')['data-turbo-confirm']).to eq('Abandonner le brouillon de « Aides » ? Les modifications non publiées seront perdues.')
    end
  end

  describe 'historique d’une fiche publiée modifiée en brouillon' do
    let(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let(:fiches) do
      { 'demarches' => [demarche, :nom, 'Nom', 'Aides', 'Aides sociales'],
        'solutions' => [Solution.create!(nom: 'Bouquet', slug: 'bouquet', visible: true), :nom, 'Nom', 'Bouquet', 'Bouquet familial'],
        'recommandations' => [Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_2, donnees_utiles: 'Quotient', visible: true),
                              :donnees_utiles, 'Données utiles disponibles', 'Quotient', 'Revenu fiscal'] }
    end

    before { sign_in admin }

    def versions(chemin, ligne)
      get "/admin/historique/#{chemin}/#{ligne.id}"
      response.parsed_body.css('main section').map { |version| [version.at_css('h2').text.squish, version.css('tbody tr').map { it.css('th, td').map { it.text.squish } }] }
    end

    it 'inscrit chaque Enregistrer en brouillon, avec son auteur et les champs changés' do
      fiches.each do |chemin, (ligne, champ, libelle, avant, apres)|
        patch "/admin/#{chemin}/#{ligne.id}", params: { ligne.model_name.param_key => { champ => apres } }

        titre, lignes = versions(chemin, ligne).first
        expect(titre).to start_with("Modification en brouillon par #{admin.email} le "), chemin
        expect(lignes).to eq([[libelle, avant, apres]]), chemin
      end
    end

    it 'inscrit le retrait d’une recommandation et sa remise' do
      recommandation = fiches['recommandations'].first
      delete "/admin/recommandations/#{recommandation.id}", params: { ligne: 1 }
      patch "/admin/recommandations/#{recommandation.id}", params: { ligne: 1, recommandation: { retiree: '0' } }

      expect(versions('recommandations', recommandation).first(2).map(&:last)).to eq([[%w[Retirée Oui Non]], [%w[Retirée Non Oui]]])
    end

    it 'inscrit la publication et l’abandon du brouillon, chacun sur sa ligne' do
      fiches.each do |chemin, (ligne, champ, libelle, avant, apres)|
        cle = ligne.model_name.param_key
        patch "/admin/#{chemin}/#{ligne.id}", params: { cle => { champ => apres } }
        patch "/admin/#{chemin}/#{ligne.id}", params: { cle => { visible: '1' } }
        patch "/admin/#{chemin}/#{ligne.id}", params: { cle => { champ => avant } }
        patch "/admin/#{chemin}/#{ligne.id}/abandonner_brouillon"

        lignes = versions(chemin, ligne).first(4)
        expect(lignes.map { it.first[/\A.+ par #{admin.email}/] }).to eq(['Abandon du brouillon', 'Modification en brouillon', 'Publication du brouillon', 'Modification en brouillon'].map { "#{it} par #{admin.email}" }), chemin
        expect(lignes.map(&:last)).to eq([[[libelle, avant, apres]], [[libelle, apres, avant]], [[libelle, avant, apres]], [[libelle, avant, apres]]]), chemin
      end
    end
  end

  describe 'recommandations d’une démarche publiée' do
    let!(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let!(:publiee) { Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Mes Aides', categorie: 'api'), niveau: :niveau_2, donnees_utiles: 'Quotient', visible: true) }
    let(:nouvelle) { Recommandation.find_by!(solution: Solution.find_by!(nom: 'Bouquet')) }

    before { sign_in admin }

    def etat_de_la_fiche = response.parsed_body.at_css(ETAT_DE_LA_FICHE)
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

    it 'compte les recommandations en brouillon dans la etat_de_la_fiche de la démarche et les publie avec elle' do
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { donnees_utiles: 'Revenu fiscal' } }
      ajouter_bouquet
      get "/admin/demarches/#{demarche.id}/edit"
      expect(etat_de_la_fiche.text.squish).to include('2 recommandations en brouillon')

      expect { patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides', visible: '1' } } }.to change(PaperTrail::Version, :count).by(2)
      expect(cartes_publiques.map { it[/Mes Aides|Bouquet/] }).to contain_exactly('Mes Aides', 'Bouquet')
      expect(cartes_publiques.join).to include('Revenu fiscal')
      expect(Recommandation.where.not(brouillon: nil)).to be_empty
      get "/admin/demarches/#{demarche.id}/edit"
      expect(etat_de_la_fiche.text).not_to include('en brouillon')
    end

    it 'annonce dans sa etat_de_la_fiche la recommandation qui paraîtra avec la démarche, la publie seule sur son Publier' do
      ajouter_bouquet
      follow_redirect!
      expect(response.body).to include('« Aides → Bouquet (API) » : brouillon enregistré, non publié.')
      expect(etat_de_la_fiche.text.squish).to include('Masquée', 'Brouillon — sera publiée avec la démarche')

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
      expect(etat_de_la_fiche.text.squish).not_to include('sera publiée avec la démarche')
      get "/admin/demarches/#{demarche.id}/edit"
      expect(etat_de_la_fiche.text).not_to include('en brouillon')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(publiee.reload.visible).to be(false)
      expect(cartes_publiques).to be_empty
    end

    it 'publie avec la démarche masquée la recommandation ajoutée depuis son onglet' do
      demarche.update!(visible: false)
      publiee.update!(visible: false)
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: demarche.id, solution_id: Solution.create!(nom: 'Bouquet', categorie: 'api').id, niveau: 'niveau_2' } }

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(cartes_publiques.map { it[/Mes Aides|Bouquet/] }).to eq(['Bouquet'])
      expect(nouvelle.reload.slice(:visible, :brouillon)).to eq('visible' => true, 'brouillon' => nil)
    end

    it 'met la démarche en brouillon, à prévisualiser et à abandonner, dès qu’une recommandation attend sa publication' do
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { donnees_utiles: 'Revenu fiscal' } }
      get "/admin/demarches/#{demarche.id}/edit"
      expect(etat_de_la_fiche.text.squish).to include('Brouillon non publié', 'Prévisualiser', 'Abandonner le brouillon')
    end

    it 'supprime à l’abandon du brouillon de la démarche les recommandations ajoutées depuis sa publication, et elles seules' do
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { donnees_utiles: 'Revenu fiscal' } }
      ajouter_bouquet
      ajoutee = nouvelle
      ancienne = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API Impôt', categorie: 'api'), niveau: :niveau_2, visible: true)
      patch "/admin/recommandations/#{ancienne.id}", params: { recommandation: { visible: '0' } }
      patch "/admin/recommandations/#{ancienne.id}", params: { ligne: 1, recommandation: { niveau: 'niveau_1' } }

      patch "/admin/demarches/#{demarche.id}/abandonner_brouillon"
      get "/admin/demarches/#{demarche.id}/edit"
      expect(response.parsed_body.css('.cartes-recommandees h3').map(&:text)).not_to include(ajoutee.solution.libelle_admin)
      expect(ancienne.reload.slice(:niveau, :visible, :brouillon)).to eq('niveau' => 'niveau_2', 'visible' => false, 'brouillon' => nil)

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(cartes_publiques.map { it[/Mes Aides|Bouquet|API Impôt/] }).to eq(['Mes Aides'])
    end

    it 'défait à l’abandon du brouillon de la démarche la modification d’une solution recommandée déjà publiée' do
      publiee.update!(description: 'Calcule les aides')
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { description: 'Calcule les aides du foyer' } }
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { contexte: 'Nouveau' } }

      patch "/admin/demarches/#{demarche.id}/abandonner_brouillon"
      get "/admin/demarches/#{demarche.id}/edit"
      expect(response.parsed_body.at_css('section[aria-labelledby="a-la-publication"]')).to be_nil
      get "/admin/recommandations/#{publiee.id}/edit"
      expect(response.parsed_body.at_css('#recommandation_description').text.strip).to eq('Calcule les aides')
      expect(cartes_publiques.first).not_to include('du foyer')
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

  describe 'retrait d’une recommandation pendant le brouillon d’une démarche publiée' do
    let!(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let!(:carte) { Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Mes Aides', categorie: 'api'), niveau: :niveau_2, donnees_utiles: 'Quotient', visible: true) }
    let(:immediate) { 'La suppression est immédiate, même pendant un brouillon : « Abandonner le brouillon » ne la remet pas.' }

    before { sign_in admin }

    def page = response.parsed_body
    def fiche = get("/admin/demarches/#{demarche.id}/edit").then { page }
    def encadre = page.at_css('section[aria-labelledby="a-la-publication"]')
    def changements = encadre&.css('li a.fr-link')&.map { it.text.squish }
    def cartes_publiques = get('/demarches/aides').then { page.css('.reco-card').map { it.text.squish } }
    def carte_de_la_fiche(recommandation) = page.at_css("li##{ActionView::RecordIdentifier.dom_id(recommandation)}")

    it 'garde en ligne la solution recommandée retirée depuis la fiche, barrée avec « Retirée · à publier » et « Remettre », jusqu’à la publication' do
      fiche
      expect(page.at_css("button[form='#{ActionView::RecordIdentifier.dom_id(carte, :suppression)}']")['data-turbo-confirm']).to eq('Supprimer la recommandation Mes Aides (API) ?')

      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('« Aides → Mes Aides (API) » : brouillon enregistré, non publié.')
      expect(Recommandation.exists?(carte.id)).to be(true)
      expect(cartes_publiques.join).to include('Mes Aides')

      fiche
      retiree = carte_de_la_fiche(carte)
      expect(retiree['class']).to include('retiree')
      expect(retiree.at_css('s').text).to eq('Mes Aides (API)')
      expect(retiree.at_css('.fr-badge.fr-badge--warning').text.squish).to eq('Retirée · à publier')
      expect(retiree.css('button').map { it.text.squish }).to eq(['Remettre Mes Aides (API)'])
      expect(encadre.at_css('#a-la-publication').text.squish).to eq('À la publication, 1 changement partira')
      expect(changements).to eq(['Solution recommandée retirée : Mes Aides (API)'])
    end

    it 'garde en ligne celle retirée depuis sa propre fiche, sans annoncer de suppression immédiate' do
      get "/admin/recommandations/#{carte.id}/edit"
      expect(page.css('form[data-turbo-confirm]').pluck('data-turbo-confirm')).to include('Supprimer « Aides → Mes Aides (API) » ?')
      expect(response.body).not_to include(immediate)

      delete "/admin/recommandations/#{carte.id}"
      follow_redirect!
      expect(response.body).to include('« Aides → Mes Aides (API) » : brouillon enregistré, non publié.')
      expect(Recommandation.exists?(carte.id)).to be(true)
      expect(cartes_publiques.join).to include('Mes Aides')
    end

    it 'annonce « Retirée · à publier » dans l’encadré de la page de la recommandation retirée, à la place du brouillon à publier' do
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }

      get "/admin/recommandations/#{carte.id}/edit"
      etat = page.at_css(ETAT_DE_LA_FICHE)
      expect(etat.css('.fr-badge').map { it.text.squish }).to eq(['Publiée', 'Retirée · à publier'])
      expect(etat.at_css('.fr-badge--warning').text.squish).to eq('Retirée · à publier')
      expect(etat.text.squish).to include('Brouillon du', 'Abandonner le brouillon')
    end

    it 'cache de la prévisualisation la solution recommandée retirée' do
      autre = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Bouquet', categorie: 'api'), niveau: :niveau_2, visible: true)
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }

      get "/admin/demarches/#{demarche.id}/previsualisation"
      expect(page.css('.reco-card').map { it.text.squish }.join).to include('Bouquet')
      expect(page.css('.reco-card').map { it.text.squish }.join).not_to include('Mes Aides')
      expect(autre.reload.brouillon).to be_nil
    end

    it 'garde en ligne la donnée utile retirée, barrée dans « Données disponibles » et dans sa fenêtre avec « Retirée · à publier » et « Remettre »' do
      utile = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_1, visible: true)

      delete "/admin/recommandations/#{utile.id}", params: { ligne: 1, fenetre: 'donnees-utiles' }
      expect(Recommandation.exists?(utile.id)).to be(true)

      fiche
      disponible = page.at_css('.donnees-disponibles li.retiree')
      expect(disponible.at_css('s').text).to eq('API QF (API)')
      expect(disponible.at_css('.fr-badge.fr-badge--warning').text.squish).to eq('Retirée · à publier')
      expect(disponible.css('button').map { it.text.squish }).to eq(['Remettre API QF (API)'])
      ligne = page.at_css("form##{ActionView::RecordIdentifier.dom_id(utile, :donnee_utile)}")
      expect(ligne.at_css('legend s').text).to eq('API QF (API)')
      expect(ligne.at_css('.fr-badge.fr-badge--warning').text.squish).to eq('Retirée · à publier')
      expect(ligne.css('button').map { it.text.squish }).to eq(['Remettre API QF (API)'])
      expect(ligne.css('select, input:not([type=hidden]), textarea')).to be_empty
      expect(changements).to eq(['Donnée utile retirée : API QF (API)'])
    end

    def formulaire_de_remise(recommandation)
      bouton = fiche.css('button').find { it.text.squish == "Remettre #{recommandation.solution.libelle_admin}" }
      page.at_css("form##{bouton['form']}")
    end

    def remettre(recommandation, **params)
      formulaire = formulaire_de_remise(recommandation)
      patch formulaire['action'], params: formulaire.css('input[type=hidden]').to_h { [it['name'], it['value']] }.merge(params), as: :turbo_stream
    end

    it 'remet la solution recommandée retirée avec « Remettre », sans rien laisser à publier' do
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }

      remettre(carte)
      expect(response).to have_http_status(:ok)
      expect(carte.reload.brouillon).to be_nil

      fiche
      expect(carte_de_la_fiche(carte)['class']).not_to include('retiree')
      expect(carte_de_la_fiche(carte).css('button').map { it.text.squish }).to eq(['Modifier Mes Aides (API)', 'Retirer Mes Aides (API)', 'Ajouter une intégration à Mes Aides (API)'])
      expect(encadre).to be_nil
    end

    it 'garde à la remise les autres changements du brouillon de la recommandation' do
      patch "/admin/recommandations/#{carte.id}", params: { ligne: 1, recommandation: { donnees_utiles: 'Revenu fiscal' } }
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }

      remettre(carte)
      expect(carte.reload.brouillon).to include('donnees_utiles' => 'Revenu fiscal')
      fiche
      expect(changements).to eq(['Solution recommandée modifiée : Mes Aides (API)'])
    end

    it 'garde le retrait quand l’autre changement de la recommandation revient à sa valeur en ligne' do
      patch "/admin/recommandations/#{carte.id}", params: { ligne: 1, recommandation: { donnees_utiles: 'Revenu fiscal' } }
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }

      patch "/admin/recommandations/#{carte.id}", params: { recommandation: { donnees_utiles: 'Quotient' } }
      fiche
      expect(changements).to eq(['Solution recommandée retirée : Mes Aides (API)'])
    end

    it 'remet la donnée utile retirée depuis sa fenêtre, en le disant dans la fenêtre' do
      utile = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_1, visible: true)
      delete "/admin/recommandations/#{utile.id}", params: { ligne: 1, fenetre: 'donnees-utiles-rattachees-a-aucune-solution' }

      remettre(utile, fenetre: 'donnees-utiles-rattachees-a-aucune-solution')
      flux = Nokogiri::HTML5.fragment(response.body).css('turbo-stream').find { it['target'] == 'message-donnees-utiles-rattachees-a-aucune-solution' }
      expect(flux.text.squish).to eq('« Aides → API QF (API) » enregistré.')
      expect(utile.reload.brouillon).to be_nil
      fiche
      expect(page.at_css('.donnees-disponibles li.retiree')).to be_nil
    end

    it 'supprime à la publication de la démarche chaque recommandation retirée, les autres cartes gardant leur ordre' do
      premiere, derniere = %w[Bouquet Impôt].map.with_index(1) { |nom, ordre| Recommandation.create!(demarche:, solution: Solution.create!(nom:, categorie: 'api'), niveau: :niveau_2, ordre:, visible: true) }
      carte.update!(ordre: 2)
      utile = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_1, visible: true)
      [carte, utile].each { delete "/admin/recommandations/#{it.id}", params: { ligne: 1 } }

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(Recommandation.where(id: [carte.id, utile.id])).to be_empty
      expect(cartes_publiques.map { it[/Bouquet|Impôt|Mes Aides/] }).to eq(%w[Bouquet Impôt])
      expect([premiere, derniere].map { it.reload.brouillon }).to eq([nil, nil])
      fiche
      expect(encadre).to be_nil
    end

    it 'supprime à la publication la recommandation retirée que l’import a masquée entre-temps' do
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }
      carte.update!(visible: false)

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(Recommandation.exists?(carte.id)).to be(false)
    end

    it 'remet à l’abandon du brouillon chaque recommandation retirée, seule ou avec d’autres changements' do
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }
      fiche
      expect(encadre.css('button').map { it.text.squish }).to include('Abandonner le brouillon')

      patch "/admin/demarches/#{demarche.id}/abandonner_brouillon"
      expect(carte.reload.brouillon).to be_nil
      expect(cartes_publiques.join).to include('Mes Aides')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { contexte: 'Nouveau' } }
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }
      patch "/admin/demarches/#{demarche.id}/abandonner_brouillon"
      expect([carte.reload.brouillon, demarche.reload.brouillon]).to eq([nil, nil])
      fiche
      expect(carte_de_la_fiche(carte)['class']).not_to include('retiree')
    end

    it 'supprime la recommandation retirée publiée depuis sa propre page, et oublie le retrait de celle qu’on y masque' do
      autre = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Bouquet', categorie: 'api'), niveau: :niveau_2, visible: true)
      [carte, autre].each { delete "/admin/recommandations/#{it.id}", params: { ligne: 1 } }

      patch "/admin/recommandations/#{carte.id}", params: { recommandation: { visible: '1' } }
      expect(response).to redirect_to('/admin/recommandations')
      follow_redirect!
      expect(response.body).to include('« Aides → Mes Aides (API) » supprimé.')
      expect(Recommandation.exists?(carte.id)).to be(false)

      patch "/admin/recommandations/#{autre.id}", params: { recommandation: { visible: '0' } }
      expect(autre.reload.slice(:visible, :brouillon)).to eq('visible' => false, 'brouillon' => nil)
      fiche
      expect(carte_de_la_fiche(autre)['class']).not_to include('retiree')
    end

    it 'supprime tout de suite sur une démarche masquée, et la recommandation ajoutée au brouillon' do
      ajoutee = Recommandation.new(demarche:, solution: Solution.create!(nom: 'Bouquet', categorie: 'api'), niveau: :niveau_2).tap { it.enregistrer({}) }
      delete "/admin/recommandations/#{ajoutee.id}", params: { ligne: 1 }
      expect(Recommandation.exists?(ajoutee.id)).to be(false)

      demarche.update!(visible: false)
      delete "/admin/recommandations/#{carte.id}", params: { ligne: 1 }
      expect(Recommandation.exists?(carte.id)).to be(false)
    end
  end

  describe 'données utiles d’une démarche publiée' do
    let!(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let!(:bouquet) { Solution.create!(nom: 'Bouquet', categorie: 'brique_logicielle', organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')]) }
    let!(:utile) do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      Integration.create!(integratrice: bouquet, integree: api, type_integration: 'expose')
      Recommandation.create!(demarche:, solution: api, niveau: :niveau_1, description: 'Quotient du mois', visible: true)
    end

    before do
      Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, visible: true)
      sign_in admin
    end

    def api_exposee(nom)
      Solution.create!(nom:, categorie: 'api').tap { Integration.create!(integratrice: bouquet, integree: it, type_integration: 'expose') }
    end

    def ajouter(nom)
      api = api_exposee(nom)
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: demarche.id, solution_id: api.id, niveau: 'niveau_1' } }
      Recommandation.find_by!(solution: api)
    end

    def carte_publique = get('/demarches/aides').then { response.parsed_body.at_css('.reco-card').text.squish }
    def badge_dans_la_demarche(ligne) = get("/admin/demarches/#{demarche.id}/edit").then { response.parsed_body.at_css("form#donnee_utile_recommandation_#{ligne.id} .fr-badge")&.text }

    it 'garde hors du site la description modifiée jusqu’à la publication de la démarche, en comptant le brouillon' do
      patch "/admin/recommandations/#{utile.id}", params: { recommandation: { description: 'Revenu du foyer' } }
      follow_redirect!
      expect(response.body).to include('« Aides → API QF (API) » : brouillon enregistré, non publié.')
      expect(carte_publique).to include('Quotient du mois')
      expect(carte_publique).not_to include('Revenu du foyer')
      expect([badge_dans_la_demarche(utile), utile.reload.brouillon?]).to eq([nil, true])
      expect(response.parsed_body.at_css(ETAT_DE_LA_FICHE).text.squish).to include('1 recommandation en brouillon')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(carte_publique).to include('Revenu du foyer')
      expect(utile.reload.brouillon?).to be(false)
    end

    it 'garde hors du site la donnée utile ajoutée, publiée ensuite avec la démarche' do
      ajoutee = ajouter('API Impôt')
      expect(carte_publique).not_to include('API Impôt')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(carte_publique).to include('API Impôt')
      expect([badge_dans_la_demarche(ajoutee), ajoutee.reload.visible?]).to eq([nil, true])
    end

    it 'garde hors du site la recommandation masquée passée en donnée utile, jusqu’à la publication de la démarche ou l’abandon' do
      api = Solution.create!(nom: 'API Impôt', categorie: 'api')
      Integration.create!(integratrice: bouquet, integree: api, type_integration: 'expose')
      masquee = Recommandation.create!(demarche:, solution: api, niveau: :niveau_2)
      patch "/admin/recommandations/#{masquee.id}", params: { ligne: 1, recommandation: { niveau: 'niveau_1' } }
      expect(carte_publique).not_to include('API Impôt')
      patch "/admin/recommandations/#{masquee.id}/abandonner_brouillon"
      expect(masquee.reload.slice(:niveau, :brouillon)).to eq('niveau' => 'niveau_2', 'brouillon' => nil)
      expect(carte_publique).not_to include('API Impôt')
      patch "/admin/recommandations/#{masquee.id}", params: { ligne: 1, recommandation: { niveau: 'niveau_1' } }

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(carte_publique).to include('API Impôt')
      expect([badge_dans_la_demarche(masquee), masquee.reload.visible?]).to eq([nil, true])
    end

    it 'garde en brouillon la recommandation masquée avec un brouillon, passée en donnée utile, jusqu’à la publication de la démarche' do
      api = Solution.create!(nom: 'API Impôt', categorie: 'api')
      Integration.create!(integratrice: bouquet, integree: api, type_integration: 'expose')
      masquee = Recommandation.create!(demarche:, solution: api, niveau: :niveau_2, visible: true)
      patch "/admin/recommandations/#{masquee.id}", params: { recommandation: { description: 'Impôt du foyer' } }
      patch "/admin/recommandations/#{masquee.id}", params: { recommandation: { visible: '0' } }

      patch "/admin/recommandations/#{masquee.id}", params: { ligne: 1, recommandation: { niveau: 'niveau_1' } }
      expect(carte_publique).not_to include('API Impôt')
      expect(badge_dans_la_demarche(masquee)).to eq('Ajoutée au brouillon')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(carte_publique).to include('API Impôt')
      expect([badge_dans_la_demarche(masquee), masquee.reload.visible?]).to eq([nil, true])
    end

    it 'garde hors du site la donnée utile publiée depuis sa fiche de création, jusqu’à la publication de la démarche' do
      api = api_exposee('API Impôt')
      post '/admin/recommandations', params: { recommandation: { demarche_id: demarche.id, solution_id: api.id, niveau: 'niveau_1', visible: '1' } }
      expect(carte_publique).not_to include('API Impôt')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(carte_publique).to include('API Impôt')
    end

    it 'garde hors du site la recommandation masquée publiée en donnée utile, jusqu’à la publication de la démarche' do
      api = api_exposee('API Impôt')
      masquee = Recommandation.create!(demarche:, solution: api, niveau: :niveau_2)
      patch "/admin/recommandations/#{masquee.id}", params: { recommandation: { niveau: 'niveau_1', visible: '1' } }
      expect(carte_publique).not_to include('API Impôt')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(carte_publique).to include('API Impôt')
    end

    it 'garde publiée comme recommandation celle publiée en donnée utile, jusqu’à la publication de la démarche' do
      api = api_exposee('API Impôt')
      publiee = Recommandation.create!(demarche:, solution: api, niveau: :niveau_2, visible: true)
      patch "/admin/recommandations/#{publiee.id}", params: { recommandation: { niveau: 'niveau_1', visible: '1' } }
      expect(carte_publique).not_to include('API Impôt')
      expect([badge_dans_la_demarche(publiee), publiee.reload.brouillon?]).to eq([nil, true])

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(carte_publique).to include('API Impôt')
    end

    it 'publie avec la démarche masquée la donnée utile qui y a été ajoutée' do
      demarche.update!(visible: false)
      ajoutee = ajouter('API Impôt')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      expect(carte_publique).to include('API Impôt')
      expect([badge_dans_la_demarche(ajoutee), ajoutee.reload.visible?]).to eq([nil, true])
    end
  end

  describe 'prévisualisation d’une fiche avec son brouillon' do
    let!(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true) }
    let(:solution) { Solution.create!(nom: 'Bouquet', slug: 'bouquet', visible: true) }

    def lien_previsualiser(chemin)
      get "/admin/#{chemin}/edit"
      response.parsed_body.css(ETAT_DE_LA_FICHE).at_css('a:contains("Prévisualiser")')
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
      expect(bandeau.text.squish).to include('Prévisualisation', 'non publiée', 'recommandations y paraissent telles qu’elles seront publiées avec la démarche', 'intégrations, dans leur version publiée')
      expect(response.headers['X-Robots-Tag']).to eq('noindex')
      expect(response.parsed_body.at_css('title').text).to start_with('Prévisualisation - Cas').and include('Aides sociales')

      get '/demarches/aides'
      expect([response.parsed_body.at_css('h1').text.squish, bandeau]).to eq(['Aides', nil])
      expect(demarche.reload.nom).to eq('Aides')
    end

    it 'montre les recommandations et données utiles qui partiront avec la démarche, absentes du site' do
      sign_in admin
      bouquet = Solution.create!(nom: 'Bouquet', categorie: 'brique_logicielle', organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      api = Solution.create!(nom: 'API Impôt', categorie: 'api').tap { Integration.create!(integratrice: bouquet, integree: it, type_integration: 'expose') }
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: demarche.id, solution_id: bouquet.id, niveau: 'niveau_2' } }
      patch "/admin/recommandations/#{Recommandation.last.id}", params: { ligne: 1, recommandation: { donnees_utiles: 'Revenu fiscal' } }
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: demarche.id, solution_id: api.id, niveau: 'niveau_1' } }
      en_ligne = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Mes Aides', categorie: 'api'), niveau: :niveau_2, ordre: 1, donnees_utiles: 'Quotient', visible: true)
      patch "/admin/recommandations/#{en_ligne.id}", params: { ligne: 1, recommandation: { donnees_utiles: 'Revenu du foyer' } }

      get lien_previsualiser("demarches/#{demarche.id}")['href']
      cartes = response.parsed_body.css('.reco-card').map { it.text.squish }
      expect(cartes.size).to eq(2)
      expect(cartes.first).to include('Mes Aides', 'Revenu du foyer')
      expect(cartes.second).to include('Bouquet', 'Revenu fiscal', 'API Impôt')

      get '/demarches/aides'
      expect(response.parsed_body.css('.reco-card').map { it.text.squish }).to contain_exactly(include('Mes Aides', 'Quotient'))
    end

    it 'montre la page que « Publier » produira, niveau et ordre des brouillons compris' do
      sign_in admin
      bouquet = Solution.create!(nom: 'Bouquet', categorie: 'brique_logicielle', organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      api = Solution.create!(nom: 'API Impôt', categorie: 'api').tap { Integration.create!(integratrice: bouquet, integree: it, type_integration: 'expose') }
      Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, ordre: 1, visible: true)
      devenue_utile = Recommandation.create!(demarche:, solution: api, niveau: :niveau_2, ordre: 2, visible: true)
      remontee = Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Mes Aides', categorie: 'api'), niveau: :niveau_2, ordre: 3, visible: true)
      patch "/admin/recommandations/#{devenue_utile.id}", params: { ligne: 1, recommandation: { niveau: 'niveau_1' } }
      patch "/admin/recommandations/#{remontee.id}", params: { ligne: 1, recommandation: { ordre: '0' } }

      get lien_previsualiser("demarches/#{demarche.id}")['href']
      apercu = response.parsed_body.css('.reco-card').map { it.text.squish }
      expect(apercu.map { it[/Mes Aides|Bouquet|API Impôt/] }).to eq(['Mes Aides', 'Bouquet'])
      expect(apercu.second).to include('API Impôt')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '1' } }
      get '/demarches/aides'
      expect(response.parsed_body.css('.reco-card').map { it.text.squish }).to eq(apercu)
    end

    describe 'carte avec une solution intégratrice' do
      let(:api) { Solution.create!(nom: 'API Impôt', categorie: 'api', visible: true) }
      let(:portail) { Solution.create!(nom: 'Portail', categorie: 'site_de_consultation', visible: true, slug: 'portail') }

      before do
        sign_in admin
        bouquet = Solution.create!(nom: 'Bouquet', categorie: 'brique_logicielle', visible: true, slug: 'bouquet-api',
          organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
        Integration.create!(integratrice: bouquet, integree: api, type_integration: 'expose')
        Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, ordre: 1, visible: true)
        Recommandation.create!(demarche:, solution: api, niveau: :niveau_1, visible: true)
      end

      def solutions_integratrices_vues(chemin)
        get chemin
        expect(response).to have_http_status(:ok)
        ['.reco-card', '#solutions-integratrices'].map { response.parsed_body.at_css(it)&.text.to_s[/Portail/] }
      end

      def integration_du_portail(demarches: [])
        Integration.create!(integratrice: portail, integree: api, type_integration: 'consomme', statut: Integration::STATUT_EN_PRODUCTION, demarches:)
      end

      it 'montre la solution intégratrice dans la carte et dans « Solutions intégratrices »' do
        integration_du_portail(demarches: [demarche])

        expect(solutions_integratrices_vues("/admin/demarches/#{demarche.id}/previsualisation")).to eq(%w[Portail Portail])
      end

      it 'montre l’intégration cochée dans le brouillon, absente du site' do
        cochee = integration_du_portail
        patch "/admin/demarches/#{demarche.id}", params: { demarche: { integration_ids: ['', cochee.id] } }

        expect(solutions_integratrices_vues("/admin/demarches/#{demarche.id}/previsualisation")).to eq(%w[Portail Portail])
        expect(solutions_integratrices_vues('/demarches/aides')).to eq([nil, nil])
      end

      it 'cache l’intégration décochée dans le brouillon, encore sur le site' do
        integration_du_portail(demarches: [demarche])
        patch "/admin/demarches/#{demarche.id}", params: { demarche: { integration_ids: [''] } }

        expect(solutions_integratrices_vues("/admin/demarches/#{demarche.id}/previsualisation")).to eq([nil, nil])
        expect(solutions_integratrices_vues('/demarches/aides')).to eq(%w[Portail Portail])
      end
    end

    it 'garde Prévisualisation devant le title SEO du brouillon' do
      sign_in admin
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { titre_seo: 'Aides selon le quotient' } }

      get "/admin/demarches/#{demarche.id}/previsualisation"
      expect(response.parsed_body.at_css('title').text).to eq('Prévisualisation - Aides selon le quotient')
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

    def lignes_par_titre(libelle)
      panneau(libelle).css('h2').to_h do |titre|
        tableau = response.parsed_body.at_css("table[aria-labelledby=\"#{titre['id']}\"]")
        [titre.text, tableau.css('tbody tr').map { |ligne| ligne.css('select').map { it.at_css('option[selected]')&.text } }]
      end
    end

    it 'range la solution en onglets : API fournies, API intégrées et solutions qui l’intègrent ligne à ligne, les démarches qui la recommandent en lecture' do
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      bouquet = Solution.create!(nom: 'Bouquet', categorie: 'brique_logicielle')
      aides = Demarche.create!(nom: 'Aides')
      Recommandation.create!(demarche: aides, solution: api_qf, niveau: :niveau_1)
      %w[consomme expose].each { |type_integration| Integration.create!(integratrice: bouquet, integree: api_qf, type_integration:) }

      get "/admin/solutions/#{api_qf.id}/edit"
      expect(onglets).to eq([['Fiche', 'button', 'true'], ['API fournies (0)', 'button', 'false'], ['API intégrées (0)', 'button', 'false'],
                             ['Solutions qui l’intègrent (2)', 'button', 'false'], ['Recommandée dans (1)', 'button', 'false'], ['Historique', 'button', 'false']])
      expect(panneau('Fiche').at_css('input[name="solution[nom]"]')).to be_present
      expect(lignes_par_titre('API fournies')).to eq('API fournies' => [[nil, nil]])
      expect(lignes_par_titre('API intégrées')).to eq('API intégrées' => [[nil, nil]])
      expect(lignes_par_titre('Solutions qui l’intègrent')).to eq(
        'Solutions qui l’intègrent' => [['Bouquet (Brique technique)', 'Intégrée', nil], ['Bouquet (Brique technique)', 'Fournie', nil], [nil, nil, nil]]
      )
      expect(panneau('Recommandée dans').css('a').map { |lien| [lien.text, lien['href']] }).to eq([['Aides', "/admin/demarches/#{aides.id}/edit"]])
      expect(panneau('Historique').text).to include('Création')

      get "/admin/solutions/#{bouquet.id}/edit"
      expect(onglets.map(&:first)).to eq(['Fiche', 'API fournies (1)', 'API intégrées (1)', 'Solutions qui l’intègrent (1)', 'Recommandée dans (0)', 'Historique'])
      expect(lignes_par_titre('API fournies')).to eq('API fournies' => [['API QF (API)', nil], [nil, nil]])
      expect(lignes_par_titre('API intégrées')).to eq('API intégrées' => [['API QF (API)', nil], [nil, nil]])
      expect(lignes_par_titre('Solutions qui l’intègrent')).to eq('Solutions qui l’intègrent' => [[nil, nil, nil]])
      expect(panneau('Recommandée dans').text.squish).to eq('Aucune démarche ne la recommande.')
    end

    it 'montre les API fournies dans l’ordre de la page publique, les API intégrées par libellé' do
      bouquet = Solution.create!(nom: 'Bouquet')
      [['API Zeta', 'expose', 1], ['API Alpha', 'expose', nil], ['API Beta', 'expose', 2], ['API Yota', 'consomme', 1], ['API Gamma', 'consomme', nil]].each do |nom, type_integration, ordre|
        Integration.create!(integratrice: bouquet, integree: Solution.create!(nom:, categorie: 'api'), type_integration:, ordre:)
      end

      get "/admin/solutions/#{bouquet.id}/edit"

      expect(lignes_par_titre('API fournies')['API fournies'].map(&:first)).to eq(['API Zeta (API)', 'API Beta (API)', 'API Alpha (API)', nil])
      expect(lignes_par_titre('API intégrées')['API intégrées'].map(&:first)).to eq(['API Gamma (API)', 'API Yota (API)', nil])
    end

    it 'ajoute une API fournie, sans rang, après les API fournies rangées' do
      bouquet = Solution.create!(nom: 'Bouquet')
      Integration.create!(integratrice: bouquet, integree: Solution.create!(nom: 'API Zeta', categorie: 'api'), type_integration: 'expose', ordre: 1)

      post '/admin/integrations', params: { ligne: 1, liste: 'fournies', integration: { integratrice_id: bouquet.id, integree_id: Solution.create!(nom: 'API Alpha', categorie: 'api').id, type_integration: 'expose' } }
      get "/admin/solutions/#{bouquet.id}/edit"

      expect(lignes_par_titre('API fournies')['API fournies'].map(&:first)).to eq(['API Zeta (API)', 'API Alpha (API)', nil])
    end

    it 'liste sous « Solutions qui l’intègrent » d’un bouquet les intégrations de ses API, à modifier depuis la fiche de l’API' do
      bouquet = Solution.create!(nom: 'Bouquet API Entreprise', categorie: 'brique_logicielle')
      sirene = Solution.create!(nom: 'API Sirene', categorie: 'api')
      urssaf = Solution.create!(nom: 'API Urssaf', categorie: 'api')
      [sirene, urssaf].each { Integration.create!(integratrice: bouquet, integree: it, type_integration: 'expose') }
      Integration.create!(integratrice: Solution.create!(nom: 'Portail'), integree: bouquet, type_integration: 'consomme')
      [[urssaf, 'Acheteza'], [sirene, 'Mes Aides'], [sirene, 'Acheteza']].each do |api, nom|
        Integration.create!(integratrice: Solution.find_or_create_by!(nom:), integree: api, type_integration: 'consomme', statut: '💡 en prospection')
      end

      get "/admin/solutions/#{bouquet.id}/edit"

      expect(onglets.fourth.first).to eq('Solutions qui l’intègrent (4)')
      expect(lignes_par_titre('Solutions qui l’intègrent')['Solutions qui l’intègrent']).to eq([['Portail', 'Intégrée', nil], [nil, nil, nil]])
      expect(panneau('Solutions qui l’intègrent').css('ul li').map { |ligne| [ligne.text.squish, ligne.at_css('a')['href']] }).to eq([
        ['Acheteza — via API Urssaf (API) Voir la fiche', "/admin/solutions/#{urssaf.id}/edit"],
        ['Acheteza — via API Sirene (API) Voir la fiche', "/admin/solutions/#{sirene.id}/edit"],
        ['Mes Aides — via API Sirene (API) Voir la fiche', "/admin/solutions/#{sirene.id}/edit"]
      ])
    end

    it 'relie chaque ligne d’intégration à son formulaire hors de celui de la fiche, l’autre côté fixé sur la ligne vide' do
      bouquet = Solution.create!(nom: 'Bouquet')
      integration = Integration.create!(integratrice: bouquet, integree: Solution.create!(nom: 'API QF', categorie: 'api'), type_integration: 'consomme')
      get "/admin/solutions/#{bouquet.id}/edit"
      ligne = panneau('API intégrées').at_css("tr#integration_#{integration.id}")
      formulaire = response.parsed_body.at_css("form#formulaire_integration_#{integration.id}")

      expect(ligne.css('select').map { [it['name'], it['form']] }).to eq(%w[integree_id statut].map { ["integration[#{it}]", formulaire['id']] })
      expect([formulaire['action'], formulaire.at_css('input[name=_method]')['value'], formulaire.at_css('input[name=liste]')['value'], formulaire.ancestors('form').size])
        .to eq(["/admin/integrations/#{integration.id}", 'patch', 'integrees', 0])
      expect(ligne.at_css("label[for=\"#{ligne.at_css('select')['id']}\"]").text).to eq('API ou jeu de données de l’intégration Bouquet → API QF (API) (intégrée) (obligatoire)')
      expect(ligne.at_css('a:contains("Modifier")')['href']).to eq("/admin/integrations/#{integration.id}/edit")
      expect(ligne.at_css('button[data-turbo-confirm]')['data-turbo-confirm']).to eq('Supprimer l’intégration Bouquet → API QF (API) (intégrée) ?')
      expect(response.parsed_body.at_css("form#suppression_integration_#{integration.id}").ancestors('form').size).to eq(0)

      listes = { 'fournies' => 'API fournies', 'integrees' => 'API intégrées', 'integratrices' => 'Solutions qui l’intègrent' }
      vides = listes.keys.map { response.parsed_body.at_css("form#formulaire_#{it}_integration") }
      expect(vides.map { |vide| vide.css('input[type=hidden]:not([name=authenticity_token])').to_h { [it['name'], it['value']] } }).to eq([
        { 'ligne' => '1', 'liste' => 'fournies', 'integration[integratrice_id]' => bouquet.id.to_s },
        { 'ligne' => '1', 'liste' => 'integrees', 'integration[integratrice_id]' => bouquet.id.to_s },
        { 'ligne' => '1', 'liste' => 'integratrices', 'integration[integree_id]' => bouquet.id.to_s }
      ])
      listes.each do |liste, titre|
        expect(panneau(titre).css("tr##{liste}_integration select").pluck('form').uniq).to eq(["formulaire_#{liste}_integration"])
        expect(panneau(titre).at_css("tr##{liste}_integration button").text.squish).to eq("Ajouter la nouvelle ligne de « #{titre} »")
      end
    end

    def onglet_ouvert = response.parsed_body.at_css('[role=tab][aria-selected=true]').text.squish

    it 'rouvre après l’enregistrement l’onglet de la solution où l’on était, et la fiche pour un onglet inconnu' do
      solution = Solution.create!(nom: 'Bouquet')
      get "/admin/solutions/#{solution.id}/edit"
      expect(response.parsed_body.at_css('#formulaire-fiche input[type=hidden][name=onglet]')['value']).to eq('fiche')

      patch "/admin/solutions/#{solution.id}", params: { onglet: 'historique', solution: { nom: 'Bouquet API' } }
      expect(response).to redirect_to("/admin/solutions/#{solution.id}/edit?onglet=historique")
      follow_redirect!
      expect(onglet_ouvert).to eq('Historique')
      expect(response.parsed_body.at_css('input[name=onglet]')['value']).to eq('historique')

      get "/admin/solutions/#{solution.id}/edit", params: { onglet: 'inconnu' }
      expect(onglet_ouvert).to eq('Fiche')
    end

    it 'ouvre la fiche de la solution sur une saisie refusée' do
      solution = Solution.create!(nom: 'Bouquet')
      patch "/admin/solutions/#{solution.id}", params: { onglet: 'historique', solution: { nom: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(onglet_ouvert).to eq('Fiche')
    end

    it 'refuse sur la démarche une intégration hors règle, nommée dans l’alerte du haut, sans rien enregistrer' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      fraude = Demarche.create!(nom: 'Fraude')
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api, type_integration: 'consomme')

      patch "/admin/demarches/#{fraude.id}", params: { demarche: { integration_ids: [integration.id] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.at_css('.fr-alert--error').text).to include("L’intégration « #{integration.libelle} » porte sur une API")
      expect(fraude.reload.integrations).to be_empty
    end

    it 'pré-remplit l’intégratrice d’une nouvelle intégration' do
      bouquet = Solution.create!(nom: 'Bouquet')
      get '/admin/integrations/new', params: { integratrice_id: bouquet.id }
      expect(response.parsed_body.at_css('#integration_integratrice_id option[selected]').text).to eq('Bouquet')
    end
  end

  describe 'fiche d’une démarche lue comme la page publique' do
    let(:publics) { Vocabulaire.create!(nom: 'Entreprises', slug: 'entreprises', categorie: 'usager') }
    let(:dlnuf) { Vocabulaire.create!(nom: 'DLNUF', slug: 'dlnuf', categorie: 'type_simplification') }
    let(:demarche) do
      Demarche.create!(nom: 'Aides', icone: '💼', slug: 'aides', description_courte: 'Aider les entreprises.', contexte: 'Un **contexte**.',
        visible: true, vocabulaires: [publics, dlnuf], types_acteurs: [TypeActeur.create!(nom: 'Communes')], cree_le: 1.day.ago, modifie_le: 1.day.ago)
    end
    let(:page) { response.parsed_body }

    before { sign_in admin }

    def fiche = get("/admin/demarches/#{demarche.id}/edit").then { page }
    def fenetre(id) = page.at_css("dialog#fenetre-#{id}")
    def champs(id) = fenetre(id).css('input:not([type=hidden]), textarea').pluck('name').uniq
    def bouton(id) = page.at_css("button[aria-controls='fenetre-#{id}'].fr-icon-edit-line")

    it 'montre l’en-tête et les blocs comme sur le site, sans etat_de_la_fiche d’état' do
      fiche
      expect(page.at_css('h1').text.squish).to eq('💼 Aides')
      expect(page.at_css('.bloc-modifiable').text.squish).to include('/demarches/aides', 'Aider les entreprises.', 'Entreprises')
      expect(page.at_css('.bloc-modifiable').text).not_to include('DLNUF')
      expect(page.at_css('#formulaire-fiche').css('h2:not(.fr-modal__title), h3').map { it.text.squish }).to eq(
        ['Contexte', 'Cadre juridique', 'Solutions recommandées (0)', 'Hors de la page publique', 'Title SEO', 'Mots-clés',
         'Fournisseurs de services', 'Vocabulaires']
      )
      expect(page.at_css('#formulaire-fiche .bloc-modifiable strong').text).to eq('contexte')
      expect(page.at_css('aside')).to be_nil
      expect(page.at_css('[role=tablist]')).to be_nil
    end

    delegate :dom_id, to: :'ActionView::RecordIdentifier'
    def integrations_de(carte) = response.parsed_body.at_css("li##{dom_id(carte)}").css('.integrations-de-la-carte li').map { it.text.squish }
    def cases_de(id) = fenetre(id).css('input[type=checkbox]').pluck('value').map(&:to_i)

    def brique_exposant(nom, *apis)
      Solution.create!(nom:, categorie: 'brique_logicielle', organisations: [Organisation.create!(nom: "Éditeur #{nom}", public_ou_prive: 'Public')]).tap do |brique|
        apis.each { Integration.create!(integratrice: brique, integree: it, type_integration: 'expose') }
      end
    end

    def integration_vers(api, nom) = Integration.create!(integratrice: Solution.create!(nom:), integree: api, type_integration: 'consomme')

    def champs_envoyes
      page.css('#formulaire-fiche input:not([type=submit]):not([type=checkbox]), #formulaire-fiche input[checked], #formulaire-fiche textarea')
        .map { [it['name'], it['value'] || it.text] }.reject { it.first.nil? }
    end

    it 'montre sur chaque carte ses intégrations cochées et ne propose dans sa fenêtre que celles de sa solution, le choix gardé au brouillon' do
      x, y = %w[X Y].map { Solution.create!(nom: "API #{it}", categorie: 'api') }
      a = Recommandation.create!(demarche:, solution: brique_exposant('Brique A', x), niveau: :niveau_2, ordre: 1)
      b = Recommandation.create!(demarche:, solution: y, niveau: :niveau_2, ordre: 2)
      Recommandation.create!(demarche:, solution: x, niveau: :niveau_1)
      cochee = integration_vers(x, 'Logiciel')
      libre = integration_vers(x, 'Portail')
      de_y = integration_vers(y, 'Guichet')
      demarche.integrations << cochee
      fiche

      expect(page.at_css("li##{dom_id(a)}").css('h4').map { it.text.squish }).to eq(['Données utiles (1)', 'Intégrations (1)'])
      expect([integrations_de(a), integrations_de(b)]).to eq([[cochee.libelle], []])
      bouton = page.at_css("li##{dom_id(a)} button[aria-controls='fenetre-integrations-#{dom_id(a)}']")
      expect(bouton.text.squish).to eq('Ajouter une intégration à Brique A (Brique technique)')
      expect([cases_de("integrations-#{dom_id(a)}"), cases_de("integrations-#{dom_id(b)}")]).to eq([[Integration.find_by!(integratrice: a.solution).id, cochee.id, libre.id], [de_y.id]])
      ancetres = fenetre("integrations-#{dom_id(a)}").ancestors.pluck('id')
      expect([ancetres.include?('formulaire-fiche'), ancetres.include?('cartes-recommandees')]).to eq([true, false])
      expect(page.css('section h2').map { it.text.squish }).not_to include('Intégrations')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { integration_ids: ['', cochee.id, libre.id] } }
      expect(response).to redirect_to("/admin/demarches/#{demarche.id}/edit")
      expect(demarche.reload.integrations).to eq([cochee])
      fiche
      expect(integrations_de(a)).to eq([cochee.libelle, libre.libelle])
    end

    it 'rend chaque intégration cochée une seule fois dans le formulaire, carte retirée et intégration hors carte comprises, et les garde à l’enregistrement d’un autre bloc' do
      x, z, w = %w[X Z W].map { Solution.create!(nom: "API #{it}", categorie: 'api') }
      Recommandation.create!(demarche:, solution: brique_exposant('Brique A', x), niveau: :niveau_2, ordre: 1)
      seconde = Recommandation.create!(demarche:, solution: brique_exposant('Brique C', x), niveau: :niveau_2, ordre: 2)
      retiree = Recommandation.create!(demarche:, solution: z, niveau: :niveau_2, ordre: 3, visible: true, brouillon: { 'retiree' => '1' })
      Recommandation.create!(demarche:, solution: x, niveau: :niveau_1)
      de_x = integration_vers(x, 'Logiciel')
      de_z = integration_vers(z, 'Portail')
      hors_carte = integration_vers(w, 'Guichet')
      demarche.integrations << [de_x, de_z]
      Integration.connection.execute("INSERT INTO demarches_integrations (demarche_id, integration_id) VALUES (#{demarche.id}, #{hors_carte.id})")
      fiche

      formulaire = page.at_css('#formulaire-fiche')
      expect(formulaire.css('input[type=checkbox][name="demarche[integration_ids][]"][checked]').pluck('value').map(&:to_i)).to contain_exactly(de_x.id, de_z.id, hors_carte.id)
      expect(formulaire.css('input[type=hidden][name="demarche[integration_ids][]"]').size).to eq(1)
      expect(page.css('[id]:not([type=hidden])').pluck('id').tally.select { |_, nombre| nombre > 1 }).to be_empty
      expect(cases_de("integrations-#{dom_id(seconde)}")).to be_empty
      expect(integrations_de(retiree)).to eq([de_z.libelle])
      expect(page.at_css("li##{dom_id(retiree)}").text).not_to include('Ajouter une intégration')
      orphelines = page.at_css('#rattachees-a-aucune-solution')
      expect(orphelines.css('.integrations-de-la-carte li').map { it.text.squish }).to eq([hors_carte.libelle])
      expect(orphelines.at_css("button[aria-controls='fenetre-integrations-rattachees-a-aucune-solution']")).to be_present

      parametres = champs_envoyes.each_with_object({}) { |(nom, valeur), h| nom.end_with?('[]') ? (h[nom] ||= []) << valeur : h[nom] = valeur }
      patch "/admin/demarches/#{demarche.id}", params: Rack::Utils.parse_nested_query(parametres.to_query).deep_merge('demarche' => { 'contexte' => 'Nouveau' })
      expect(Demarche.find(demarche.id).appliquer_brouillon.integration_ids).to contain_exactly(de_x.id, de_z.id, hors_carte.id)
    end

    it 'donne sur place sa fenêtre d’intégrations à une carte ajoutée, dans le formulaire de la fiche' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      integration = integration_vers(api, 'Logiciel')
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: demarche.id, solution_id: api.id, niveau: 'niveau_2' } }

      fenetres = Nokogiri::HTML5.fragment(response.body).css('turbo-stream').find { it['target'] == 'fenetres-des-integrations' }.at_css('template')
      expect(fenetres.at_css("dialog#fenetre-integrations-#{dom_id(Recommandation.last)}").css('input[type=checkbox]').pluck('value')).to eq([integration.id.to_s])
      expect(fenetres.css('input[type=hidden][name="demarche[integration_ids][]"]').size).to eq(1)
    end

    it 'ouvre pour chaque bloc une fenêtre avec ses seuls champs' do
      fiche
      expect(%w[entete contexte cadre-juridique titre-seo mots-clefs fournisseurs vocabulaires].to_h { [bouton(it).text, champs(it)] }).to eq(
        'Modifier l’en-tête' => ['demarche[icone]', 'demarche[nom]', 'demarche[description_courte]', 'demarche[slug]', 'demarche[vocabulaire_ids][]'],
        'Modifier le contexte' => ['demarche[contexte]'],
        'Modifier le cadre juridique' => ['demarche[cadre_juridique]'],
        'Modifier le title SEO' => ['demarche[titre_seo]'],
        'Modifier les mots-clés' => ['demarche[mots_clefs]'],
        'Modifier les fournisseurs de services' => ['demarche[type_acteur_ids][]'],
        'Modifier les vocabulaires' => ['demarche[vocabulaire_ids][]']
      )
      expect(fenetre('entete').css('input[type=checkbox]').pluck('value')).to eq([publics.id.to_s])
      expect(fenetre('vocabulaires').css('input[type=checkbox]').pluck('value')).to eq([dlnuf.id.to_s])
      expect(fenetre('contexte').css('.fr-modal__footer button').map { [it.text, it['type']] }).to eq([%w[Annuler button], %w[Enregistrer submit]])
    end

    it 'met l’état, les dates et les actions en haut, Masquer et Supprimer en bas' do
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }
      fiche
      barre = page.at_css('section[aria-label="État de la démarche"]')
      expect(barre.css('.fr-badge').map(&:text)).to eq(['Publiée', 'Brouillon non publié'])
      expect(barre.text.squish).to include('Création', 'Dernière modification', 'Brouillon du')
      expect(page.at_css('#etat-de-la-demarche').css('a.fr-btn, button').map { it.text.squish }).to eq(['Publier ce changement', 'Prévisualiser le brouillon - nouvelle fenêtre', 'Abandonner le brouillon'])
      expect(page.css('form:has(button:contains("Masquer la démarche")), form:has(button:contains("Supprimer la démarche"))').pluck('data-turbo-confirm')).to eq(
        [nil, 'Supprimer « Aides » ?']
      )
    end

    it 'mène à l’historique de la démarche depuis le bas de la fiche, à côté de « Supprimer la démarche »' do
      fiche
      bas = page.css('ul.fr-btns-group').find { it.text.include?('Supprimer la démarche') }
      expect(bas.css('li').map { it.text.squish }).to eq(['Historique de la démarche', 'Masquer la démarche', 'Supprimer la démarche'])
      expect(bas.at_css('a')['href']).to eq("/admin/historique/demarches/#{demarche.id}")
    end

    it 'ne propose pas de masquer une démarche déjà masquée' do
      demarche.update!(visible: false)
      fiche
      expect(page.text).not_to include('Masquer la démarche')
    end

    it 'garde les intégrations et les vocabulaires d’un autre bloc quand on enregistre un bloc' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      Recommandation.create!(demarche:, solution: api, niveau: 'niveau_1')
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Logiciel'), integree: api, type_integration: 'expose')
      demarche.update!(visible: false, integrations: [integration])
      fiche
      envoye = page.css('#formulaire-fiche input:not([type=submit]):not([type=checkbox]), #formulaire-fiche input[checked], #formulaire-fiche textarea')
        .map { [it['name'], it['value'] || it.text] }.reject { it.first.nil? }
      parametres = envoye.each_with_object({}) { |(nom, valeur), h| nom.end_with?('[]') ? (h[nom] ||= []) << valeur : h[nom] = valeur }
      patch "/admin/demarches/#{demarche.id}", params: Rack::Utils.parse_nested_query(parametres.to_query).deep_merge('demarche' => { 'contexte' => 'Nouveau' })

      expect(demarche.reload.slice(:contexte, :nom)).to eq('contexte' => 'Nouveau', 'nom' => 'Aides')
      expect(demarche.vocabulaires).to contain_exactly(publics, dlnuf)
      expect(demarche.integrations).to eq([integration])
      expect(response).to redirect_to("/admin/demarches/#{demarche.id}/edit")
    end

    it 'rouvre la fenêtre de l’en-tête sur un nom vide, le message sous le champ' do
      demarche.update!(visible: false)
      patch "/admin/demarches/#{demarche.id}", params: { onglet: 'fiche', demarche: { nom: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css('dialog[data-controller="fenetre-rouverte"]').pluck('id')).to eq(['fenetre-entete'])
      expect(fenetre('entete').at_css('.fr-input-group--error').text).to include('Nom', 'doit être rempli')
    end
  end

  describe 'ce qui partira à la publication d’une démarche' do
    let(:api) { Solution.create!(nom: 'API QF', categorie: 'api') }
    let(:demarche) { Demarche.create!(nom: 'Aides', slug: 'aides', visible: true, cree_le: 1.day.ago, modifie_le: 1.day.ago) }

    before { sign_in admin }

    def page = response.parsed_body

    def fiche = get("/admin/demarches/#{demarche.id}/edit").then { page }
    def encadre = page.at_css('section[aria-labelledby="a-la-publication"]')
    def lignes = encadre.css('li a.fr-link').map { [it.text.squish, it['href']] }
    def barre = page.at_css('section[aria-label="État de la démarche"]')

    it 'liste chaque bloc changé dans l’ordre de la fiche, chacun lié à son bloc, avec les actions du brouillon à la place de la barre' do
      Recommandation.create!(demarche:, solution: api, niveau: :niveau_1)
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Logiciel'), integree: api, type_integration: 'consomme')
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { contexte: 'Nouveau', slug: 'aides-sociales', nom: 'Aides sociales', integration_ids: ['', integration.id] } }
      fiche

      expect(encadre.at_css('#a-la-publication').text.squish).to eq('À la publication, 4 changements partiront')
      expect(lignes).to eq([
        ['En-tête modifié', '#titre-de-la-demarche'],
        ['Adresse de la page modifiée : l’ancienne adresse ne mènera plus à la démarche', '#titre-de-la-demarche'],
        ['Contexte modifié', '#bloc-contexte'],
        ['Intégrations modifiées', '#bloc-solutions-recommandees']
      ])
      expect(lignes.map { |_libelle, ancre| page.at_css(ancre) }).to all(be_present)
      expect(encadre.css('a.fr-btn, button').map { it.text.squish }).to eq(['Publier ces 4 changements', 'Prévisualiser le brouillon - nouvelle fenêtre', 'Abandonner le brouillon'])
      expect(barre.css('a, button')).to be_empty
    end

    it 'nomme un seul changement au singulier, et range un vocabulaire dans le bloc qui le montre' do
      dlnuf, publics = { 'DLNUF' => 'type_simplification', 'Entreprises' => 'usager' }.map { |nom, categorie| Vocabulaire.create!(nom:, slug: nom.downcase, categorie:) }
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { vocabulaire_ids: ['', dlnuf.id] } }
      fiche

      expect(encadre.at_css('#a-la-publication').text.squish).to eq('À la publication, 1 changement partira')
      expect(lignes).to eq([['Vocabulaires modifiés', '#bloc-vocabulaires']])
      expect(encadre.at_css('button').text.squish).to eq('Publier ce changement')

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { vocabulaire_ids: ['', publics.id] } }
      fiche
      expect(lignes).to eq([['En-tête modifié', '#titre-de-la-demarche']])
    end

    it 'nomme le bloc de chaque champ de la fiche' do
      Recommandation.create!(demarche:, solution: api, niveau: :niveau_1)
      champs = {
        icone: '💼', nom: 'Aides sociales', description_courte: 'Court', slug: 'aides-sociales', contexte: 'Contexte', cadre_juridique: 'Loi', titre_seo: 'SEO',
        mots_clefs: 'aide', type_acteur_ids: ['', TypeActeur.create!(nom: 'Communes').id],
        integration_ids: ['', Integration.create!(integratrice: Solution.create!(nom: 'Logiciel'), integree: api, type_integration: 'consomme').id],
        vocabulaire_ids: ['', *{ 'DLNUF' => 'type_simplification', 'Entreprises' => 'usager' }.map { |nom, categorie| Vocabulaire.create!(nom:, slug: nom.downcase, categorie:).id }]
      }
      champs.each { |champ, valeur| patch "/admin/demarches/#{demarche.id}", params: { demarche: { champ => valeur } } }
      fiche

      expect(lignes.map(&:first)).to eq(['En-tête modifié', 'Adresse de la page modifiée : l’ancienne adresse ne mènera plus à la démarche', 'Contexte modifié',
                                         'Cadre juridique modifié', 'Intégrations modifiées', 'Title SEO modifié', 'Mots-clés modifiés',
                                         'Fournisseurs de services modifiés', 'Vocabulaires modifiés'])
    end

    it 'nomme chaque recommandation ajoutée ou modifiée, liée à sa carte ou au bloc des solutions recommandées, et pas celle retirée' do
      inclusion = Solution.create!(nom: 'API Marché de l’inclusion', categorie: 'api')
      Recommandation.new(demarche:, solution: inclusion, niveau: :niveau_2).enregistrer({})
      utile = Recommandation.create!(demarche:, solution: api, niveau: :niveau_1, visible: true)
      utile.enregistrer('description' => 'Le quotient familial.')
      Recommandation.create!(demarche:, solution: Solution.create!(nom: 'Retirée', categorie: 'api'), niveau: :niveau_1, visible: true).destroy!
      fiche
      carte = demarche.recommandations.find_by(solution: inclusion)

      expect(encadre.at_css('#a-la-publication').text.squish).to eq('À la publication, 2 changements partiront')
      expect(lignes).to eq([
        ["Solution recommandée ajoutée : #{inclusion.libelle_admin}", "#recommandation_#{carte.id}"],
        ["Donnée utile modifiée : #{api.libelle_admin}", '#bloc-solutions-recommandees']
      ])
    end

    it 'résume en une ligne l’ordre des solutions recommandées, même quand chaque déplacement décale plusieurs cartes' do
      cartes = %w[A B C D].map.with_index(1) { |nom, ordre| Recommandation.create!(demarche:, solution: Solution.create!(nom:, categorie: 'api'), niveau: :niveau_2, ordre:, visible: true) }
      patch "/admin/recommandations/#{cartes.last.id}/position", params: { position: 1 }, as: :turbo_stream
      patch "/admin/recommandations/#{cartes.first.id}/position", params: { position: 4 }, as: :turbo_stream
      fiche

      expect(encadre.at_css('#a-la-publication').text.squish).to eq('À la publication, 1 changement partira')
      expect(lignes).to eq([['Ordre des solutions recommandées modifié', '#bloc-solutions-recommandees']])
      expect(page.at_css('#bloc-solutions-recommandees')).to be_present
    end

    it 'résume en une ligne l’ordre des données utiles' do
      utiles = %w[A B C].map.with_index(1) { |nom, ordre| Recommandation.create!(demarche:, solution: Solution.create!(nom:, categorie: 'api'), niveau: :niveau_1, ordre:, visible: true) }
      { utiles.first => '3', utiles.last => '1' }.each do |utile, ordre|
        patch "/admin/recommandations/#{utile.id}", params: { ligne: 1, fenetre: 'donnees-utiles', recommandation: { niveau: 'niveau_1', ordre: } }
      end
      fiche

      expect(encadre.at_css('#a-la-publication').text.squish).to eq('À la publication, 1 changement partira')
      expect(lignes).to eq([['Ordre des données utiles modifié', '#bloc-solutions-recommandees']])
    end

    it 'garde la ligne d’une solution recommandée déplacée et modifiée' do
      cartes = %w[A B].map.with_index(1) { |nom, ordre| Recommandation.create!(demarche:, solution: Solution.create!(nom:, categorie: 'api'), niveau: :niveau_2, ordre:, visible: true) }
      patch "/admin/recommandations/#{cartes.last.id}/position", params: { position: 1 }, as: :turbo_stream
      cartes.last.reload.enregistrer('description' => 'Nouvelle description')
      fiche

      expect(encadre.at_css('#a-la-publication').text.squish).to eq('À la publication, 2 changements partiront')
      expect(lignes).to contain_exactly(["Solution recommandée modifiée : #{cartes.last.solution.libelle_admin}", "#recommandation_#{cartes.last.id}"],
        ['Ordre des solutions recommandées modifié', '#bloc-solutions-recommandees'])
    end

    it 'ne compte qu’« ajoutée » pour une solution recommandée ajoutée puis changée de position, sa position faisant partie de l’ajout' do
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: demarche.id, solution_id: api.id, niveau: 'niveau_2' } }
      patch "/admin/recommandations/#{Recommandation.last.id}", params: { ligne: 1, recommandation: { ordre: '2' } }
      fiche

      expect(Recommandation.last.brouillon).to include('ordre' => '2')
      expect(lignes.map(&:first)).to eq(["Solution recommandée ajoutée : #{api.libelle_admin}"])
    end

    it 'se met à jour quand on ajoute une solution recommandée depuis la fiche' do
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: demarche.id, solution_id: api.id, niveau: 'niveau_2' } }
      flux = Nokogiri::HTML5.fragment(response.body).css('turbo-stream').find { it['target'] == 'etat-de-la-demarche' }

      expect(flux['action']).to eq('replace')
      expect(flux.at_css('section[aria-labelledby="a-la-publication"] li a.fr-link').text.squish).to eq("Solution recommandée ajoutée : #{api.libelle_admin}")
      expect(flux.at_css('form:has(button:contains("Abandonner"))')['data-turbo-confirm']).to include('« Aides »')
    end

    it 'garde les filtres de la liste dans « Publier » après une recommandation ajoutée sur place' do
      post '/admin/recommandations', params: { ligne: 1, recommandation: { demarche_id: demarche.id, solution_id: api.id, niveau: 'niveau_2' } },
        headers: { 'Referer' => "http://www.example.com/admin/demarches/#{demarche.id}/edit?q=Aides&etat=brouillon" }
      flux = Nokogiri::HTML5.fragment(response.body).css('turbo-stream').find { it['target'] == 'etat-de-la-demarche' }
      publier = flux.at_css('form:has(button:contains("Publier"))')

      expect(publier.css('input[type=hidden]').to_h { [it['name'], it['value']] }).to include('q' => 'Aides', 'etat' => 'brouillon')

      patch "/admin/recommandations/#{Recommandation.last.id}", params: { ligne: 1, recommandation: { ordre: '2' } }, headers: { 'Referer' => 'http://www.example.com/admin?q=%zz' }
      expect(response).to have_http_status(:ok)
    end

    it 'garde les filtres de la liste dans « Publier » après une carte déplacée' do
      cartes = %w[A B].map { Recommandation.create!(demarche:, solution: Solution.create!(nom: it, categorie: 'api'), niveau: :niveau_2, visible: true) }
      fiche
      deplacement = page.at_css("form#deplacement_recommandation_#{cartes.last.id}")
      patch deplacement['action'], params: deplacement.css('input[type=hidden]').to_h { [it['name'], it['value']] }.merge('position' => '1'),
        headers: { 'Referer' => "http://www.example.com/admin/demarches/#{demarche.id}/edit?q=Aides&etat=brouillon" }
      flux = Nokogiri::HTML5.fragment(response.body).css('turbo-stream').find { it['target'] == 'etat-de-la-demarche' }

      expect(flux.at_css('form:has(button:contains("Publier"))').css('input[type=hidden]').to_h { [it['name'], it['value']] }).to include('q' => 'Aides', 'etat' => 'brouillon')
    end

    it 'propose d’abandonner un brouillon qui ne fait que déplacer des cartes publiées, et remet chaque carte à sa place' do
      cartes = %w[A B].map { Recommandation.create!(demarche:, solution: Solution.create!(nom: it, categorie: 'api'), niveau: :niveau_2, visible: true) }
      fiche
      deplacement = page.at_css("form#deplacement_recommandation_#{cartes.last.id}")
      patch deplacement['action'], params: deplacement.css('input[type=hidden]').to_h { [it['name'], it['value']] }.merge('position' => '1')
      fiche
      abandon = encadre.at_css('form:has(button:contains("Abandonner le brouillon"))')

      patch abandon['action']
      fiche
      expect(page.css('.cartes-recommandees h3').map(&:text)).to eq(cartes.map { it.solution.libelle_admin })
      expect(cartes.map { it.reload.brouillon }).to eq([nil, nil])
    end

    it 'publie depuis l’encadré' do
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { contexte: 'Nouveau' } }
      fiche
      formulaire = encadre.at_css('form:has(button:contains("Publier"))')
      patch formulaire['action'], params: formulaire.css('input[type=hidden]').to_h { [it['name'], it['value']] }

      expect(demarche.reload.slice(:contexte, :brouillon)).to eq('contexte' => 'Nouveau', 'brouillon' => nil)
    end

    it 'ne paraît pas sans brouillon ni sur une démarche masquée' do
      fiche
      expect(encadre).to be_nil
      expect(barre.css('button').map(&:text)).to eq(['Publier'])

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { contexte: 'Nouveau' } }
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { visible: '0' } }
      fiche
      expect(demarche.reload).to have_attributes(visible: false, brouillon?: true)
      expect(encadre).to be_nil
    end
  end
end
