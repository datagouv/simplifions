require 'rails_helper'

RSpec.shared_examples 'un CRUD brut' do |modele, chemin|
  let(:cle) { modele.model_name.param_key }
  let(:modification) { { nom: 'Nouveau nom' } }
  let(:nouveaux) { attributs }
  let(:invalide) { [{ nom: '' }, 'Nom doit être rempli'] }
  let!(:ligne) { modele.create!(attributs) }
  let(:nom) { attributs[:nom] }
  let(:nom_cree) { nom }

  def fil_d_ariane = response.parsed_body.css('.fr-breadcrumb__list li').map { |etape| etape.text.strip }

  it 'exige la connexion' do
    get "/admin/#{chemin}"
    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'liste les lignes avec un lien de modification' do
    sign_in admin
    get "/admin/#{chemin}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<td>#{ligne.id}</td>")
    expect(response.parsed_body.at_css("tbody a[href=\"/admin/#{chemin}/#{ligne.id}/edit\"]").text).to eq(nom)
    expect(response.body).not_to include('Supprimer')
    expect(response.parsed_body.css('tbody a').map(&:text)).not_to include('Modifier')
  end

  it 'filtre la liste sur le nom, sans tenir compte des accents ni de la casse' do
    sign_in admin
    get "/admin/#{chemin}", params: { q: I18n.transliterate(nom.split.first).upcase }
    expect(response.body).to include("href=\"/admin/#{chemin}/#{ligne.id}/edit\"")
    expect(response.parsed_body.at_css('input[name=q]')['value']).to eq(I18n.transliterate(nom.split.first).upcase)
    get "/admin/#{chemin}", params: { q: 'introuvable' }
    expect(response.body).not_to include("href=\"/admin/#{chemin}/#{ligne.id}/edit\"")
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
    expect(response).to redirect_to("/admin/#{chemin}/#{modele.last.id}/edit")
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
    expect(response).to redirect_to("/admin/#{chemin}/#{ligne.id}/edit")
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
  end

  it_behaves_like 'un CRUD brut', Organisation, 'organisations' do
    let(:collection) { 'Organisations' }
    let(:attributs) { { nom: 'DINUM' } }
  end

  it_behaves_like 'un CRUD brut', TypeActeur, 'types_acteurs' do
    let(:collection) { "Types d'acteurs" }
    let(:attributs) { { nom: 'Communes' } }
  end

  it_behaves_like 'un CRUD brut', Vocabulaire, 'vocabulaires' do
    let(:collection) { 'Vocabulaires' }
    let(:attributs) { { nom: 'Particuliers', slug: 'particuliers', categorie: 'usager' } }
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
      expect(noms_listes('integrations', 'bouquet qf')).to eq(['Bouquet → API QF (API) (intégrée)'])
      expect(noms_listes('integrations', 'entreprise')).to be_empty
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

      get '/admin/demarches', params: { page: ['2'] }
      expect(response.parsed_body.css('tbody tr').size).to eq(50)
    end
  end

  describe 'colonnes des listes' do
    before { sign_in admin }

    it 'montre si la démarche, la solution ou la recommandation est visible, et sa date de modification' do
      aides = Demarche.create!(nom: 'Aides', slug: 'aides', visible: true, modifie_le: Time.zone.local(2026, 10, 4, 23, 30))
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      Recommandation.create!(demarche: aides, solution: api_qf, niveau: :niveau_1, visible: true, modifie_le: Time.zone.local(2026, 3, 1, 12))

      expect(colonnes('demarches')).to eq([{ 'Nom' => 'Aides', 'Visible' => 'Oui', 'Modifié le' => '05/10/2026' }])
      expect(colonnes('recommandations')).to eq([{ 'Ligne' => 'Aides → API QF (API)', 'Visible' => 'Oui', 'Modifié le' => '01/03/2026' }])
      expect(colonnes('solutions')).to eq([{ 'Nom' => 'API QF (API)', 'Visible' => 'Non', 'Modifié le' => '', 'Intégrée par' => '' }])
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
      integration = Integration.create!(integratrice: bouquet, integree: Solution.create!(nom: 'API QF'), type_integration: 'consomme')
      dinum = Organisation.create!(nom: 'DINUM')

      patch "/admin/integrations/#{integration.id}", params: { integration: { demarche_ids: [demarche.id] } }
      expect(integration.reload.demarches).to eq([demarche])

      patch "/admin/organisations/#{dinum.id}", params: { organisation: { solution_ids: [bouquet.id] } }
      expect(dinum.reload.solutions).to eq([bouquet])
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

    it 'range chaque longue liste de cases dans un groupe filtrable, sans champ envoyé avec le formulaire' do
      {
        'demarches' => ["Types d'acteurs", 'Intégrations'], 'solutions' => ['Organisations', "Types d'acteurs"],
        'integrations' => ['Démarches'], 'organisations' => ['Solutions'], 'types_acteurs' => %w[Démarches Solutions],
        'vocabulaires' => %w[Démarches Solutions]
      }.each do |chemin, groupes|
        get "/admin/#{chemin}/new"
        filtrables = response.parsed_body.css('fieldset[data-controller="liste-filtrable"]')
        expect(filtrables.map { |groupe| groupe.at_css('legend').text.strip }).to eq(groupes)
        filtrables.each do |groupe|
          filtre = groupe.at_css('input[type=search]')
          expect(groupe.at_css("label[for=#{filtre['id']}]").text).to include('Filtrer')
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
      patch "/admin/demarches/#{demarche.id}", params: { demarche: { slug: 'Mauvais slug' } }
      expect(response.parsed_body.at_css('a:contains("Voir la page publique")')['href']).to eq('/demarches/cantine')
    end
  end

  describe 'liens vers les éléments liés' do
    before { sign_in admin }

    def liens_vers_les_fiches(chemin)
      get chemin
      response.parsed_body.css('a:contains("Voir la fiche")').map { |lien| [lien['aria-label'], lien['href'], lien.ancestors('label').any?] }
    end

    it 'mène depuis chaque case cochée à la fiche de l’élément, hors du libellé de la case' do
      api = Solution.create!(nom: 'API QF', categorie: 'api')
      integration = Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api, type_integration: 'consomme')
      communes = TypeActeur.create!(nom: 'Communes')
      TypeActeur.create!(nom: 'Départements')
      demarche = Demarche.create!(nom: 'Aides', integrations: [integration], types_acteurs: [communes])
      usager = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager', solutions: [api])

      expect(liens_vers_les_fiches("/admin/demarches/#{demarche.id}/edit")).to contain_exactly(
        ['Voir la fiche Communes', "/admin/types_acteurs/#{communes.id}/edit", false],
        ['Voir la fiche Bouquet → API QF (API) (intégrée)', "/admin/integrations/#{integration.id}/edit", false]
      )
      expect(liens_vers_les_fiches("/admin/vocabulaires/#{usager.id}/edit")).to eq([['Voir la fiche API QF (API)', "/admin/solutions/#{api.id}/edit", false]])
      expect(liens_vers_les_fiches('/admin/demarches/new')).to be_empty
    end

    it 'mène depuis chaque vocabulaire coché d’une démarche ou d’une solution à sa fiche' do
      usager = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      Vocabulaire.create!(nom: 'Entreprises', slug: 'entreprises', categorie: 'usager')
      attendu = [['Voir la fiche Particuliers', "/admin/vocabulaires/#{usager.id}/edit", false]]

      expect(liens_vers_les_fiches("/admin/demarches/#{Demarche.create!(nom: 'Aides', vocabulaires: [usager]).id}/edit")).to eq(attendu)
      expect(liens_vers_les_fiches("/admin/solutions/#{Solution.create!(nom: 'Bouquet', vocabulaires: [usager]).id}/edit")).to eq(attendu)
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
      entetes = tableau.css('thead th').map(&:text)
      tableau.css('tbody tr').map { |ligne| entetes.zip(ligne.css('td').map { |cellule| cellule.text.squish }).to_h.slice('Solution', 'Type de recommandation', 'Ordre') }
    end

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
      encart = response.parsed_body.at_css('aside')
      expect(encart.text.squish).to include('Démarche : Aides', 'Demander une aide sociale')
      expect(encart.at_css('a[aria-label="Voir la fiche Aides"]')['href']).to eq("/admin/demarches/#{aides.id}/edit")

      expect(recommandations_de("/admin/recommandations/new?demarche_id=#{aides.id}").size).to eq(2)
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
    include ActiveSupport::Testing::TimeHelpers

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
        'demarches' => ['Icône du titre', 'Description courte', 'Cadre juridique', 'Mots-clés', 'Visible sur simplifions'],
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
        Recommandation => %w[niveau ordre], Solution => %w[uid_datagouv france_connectee types_solution slug],
        TypeActeur => %w[slugs], Demarche => %w[mots_clefs slug], Integration => %w[type_integration]
      }.each do |modele, champs|
        get "/admin/#{modele.model_name.route_key}/new"
        champs.each do |champ|
          aide = response.parsed_body.at_css("label[for=#{modele.model_name.param_key}_#{champ}] .fr-hint-text")
          expect(aide).to be_present, "#{modele}.#{champ}"
        end
      end
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

    it 'renvoie les slugs d’un type d’acteur au filtre « Démarches gérées par » du site' do
      get '/admin/types_acteurs/new'
      expect(response.parsed_body.at_css('label[for=type_acteur_slugs] .fr-hint-text').text).to include('« Démarches gérées par »')
    end

    it 'range les champs dans l’ordre des fiches Grist' do
      {
        'demarches' => ['Visible sur simplifions', 'Icône du titre', 'Nom (obligatoire)', 'Slug', 'Description courte', 'Contexte',
                        'Cadre juridique', "Types d'acteurs", 'Mots-clés', 'Vocabulaires', 'Intégrations'],
        'solutions' => ['Visible sur simplifions', 'Nom (obligatoire)', 'Slug', 'Site internet', 'URL de demande d’accès', 'Organisations',
                        'Image principale', 'Légende de l’image', 'Description courte', 'Type de solution',
                        'Catégorie de solution', 'Vocabulaires', "Types d'acteurs", 'Cette solution permet',
                        'Cette solution ne permet pas', 'Identifiant data.gouv', 'API FranceConnectée'],
        'recommandations' => ['Visible sur simplifions', 'Solution (obligatoire)', 'URL de demande d’accès pour cette démarche', 'Démarche (obligatoire)',
                              'Type de recommandation (obligatoire)', 'Ordre', 'Données utiles disponibles', 'Paramètres à saisir pour récupérer les données',
                              'En quoi cette API ou ce jeu de données est utile'],
        'integrations' => ['API ou jeu de données (obligatoire)', 'Solution (obligatoire)', 'Type d’intégration (obligatoire)', 'Statut de l’intégration', 'Démarches']
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

  describe 'image de solution' do
    it 'attache le fichier envoyé par le formulaire' do
      sign_in admin
      image = Rack::Test::UploadedFile.new(StringIO.new('img'), 'image/png', original_filename: 'swagger.png')
      post '/admin/solutions', params: { solution: { nom: 'Bouquet', image: } }
      expect(response).to redirect_to("/admin/solutions/#{Solution.last.id}/edit")
      expect(Solution.last.image).to be_attached
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
end
