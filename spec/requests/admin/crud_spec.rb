require 'rails_helper'

RSpec.shared_examples 'un CRUD brut' do |modele, chemin|
  let(:cle) { modele.model_name.param_key }
  let(:modification) { { nom: 'Nouveau nom' } }
  let(:nouveaux) { attributs }
  let(:invalide) { [{ nom: '' }, 'Nom doit être rempli'] }
  let!(:ligne) { modele.create!(attributs) }
  let(:nom) { attributs[:nom] }

  it 'exige la connexion' do
    get "/admin/#{chemin}"
    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'liste les lignes avec un lien de modification' do
    sign_in admin
    get "/admin/#{chemin}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<td>#{ligne.id}</td>")
    expect(response.body).to include("href=\"/admin/#{chemin}/#{ligne.id}/edit\"")
    expect(response.body).not_to include('Supprimer')
  end

  it 'propose la suppression depuis la fiche, en nommant la ligne' do
    sign_in admin
    get "/admin/#{chemin}/#{ligne.id}/edit"
    formulaire = response.parsed_body.at_css("form[action=\"/admin/#{chemin}/#{ligne.id}\"]:has(input[name=_method][value=delete])")
    expect(formulaire['data-turbo-confirm']).to start_with("Supprimer « #{nom} » ?")
  end

  it 'affiche les formulaires de création et de modification' do
    sign_in admin
    get "/admin/#{chemin}/new"
    expect(response.body).to include("action=\"/admin/#{chemin}\"")
    get "/admin/#{chemin}/#{ligne.id}/edit"
    expect(response.body).to include("action=\"/admin/#{chemin}/#{ligne.id}\"")
  end

  it 'nomme la ligne telle qu’en base quand une modification est refusée' do
    sign_in admin
    patch "/admin/#{chemin}/#{ligne.id}", params: { cle => invalide.first }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.at_css('form[data-turbo-confirm]')['data-turbo-confirm']).to start_with("Supprimer « #{nom} » ?")
  end

  it 'crée une ligne puis revient à la liste' do
    sign_in admin
    expect { post "/admin/#{chemin}", params: { cle => nouveaux } }.to change(modele, :count).by(1)
    expect(response).to redirect_to("/admin/#{chemin}")
    follow_redirect!
    expect(response.body).to include('Enregistré.')
  end

  it 'refuse une ligne invalide et réaffiche le formulaire avec l’erreur' do
    sign_in admin
    post "/admin/#{chemin}", params: { cle => invalide.first }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('<div class="fr-alert fr-alert--error">')
    expect(response.body).to include(invalide.last)
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

  it 'modifie une ligne' do
    sign_in admin
    patch "/admin/#{chemin}/#{ligne.id}", params: { cle => modification }
    expect(response).to redirect_to("/admin/#{chemin}")
    expect(ligne.reload.attributes).to include(modification.stringify_keys)
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

  it_behaves_like 'un CRUD brut', Demarche, 'demarches' do
    let(:attributs) { { nom: 'Aides publiques' } }
  end

  it_behaves_like 'un CRUD brut', Solution, 'solutions' do
    let(:attributs) { { nom: 'Bouquet API Particulier' } }
  end

  it_behaves_like 'un CRUD brut', Recommandation, 'recommandations' do
    let(:attributs) { { demarche_id: Demarche.create!(nom: 'Aides').id, solution_id: Solution.create!(nom: 'API QF', categorie: 'api').id, niveau: 'niveau_1' } }
    let(:modification) { { ordre: 3 } }
    let(:invalide) { [{ demarche_id: '' }, 'Demarche doit exister'] }
    let(:nouveaux) { attributs.merge(demarche_id: Demarche.create!(nom: 'Autre démarche').id) }
    let(:nom) { 'Aides → API QF' }
  end

  it_behaves_like 'un CRUD brut', Integration, 'integrations' do
    let(:attributs) do
      { integratrice_id: Solution.create!(nom: 'Bouquet').id, integree_id: Solution.create!(nom: 'API QF').id, type_integration: 'expose' }
    end
    let(:modification) { { statut: '✅ en production' } }
    let(:invalide) { [{ integratrice_id: '' }, 'Integratrice doit exister'] }
    let(:nom) { 'Bouquet → API QF (expose)' }
  end

  it_behaves_like 'un CRUD brut', Organisation, 'organisations' do
    let(:attributs) { { nom: 'DINUM' } }
  end

  it_behaves_like 'un CRUD brut', TypeActeur, 'types_acteurs' do
    let(:attributs) { { nom: 'Communes' } }
  end

  it_behaves_like 'un CRUD brut', Vocabulaire, 'vocabulaires' do
    let(:attributs) { { nom: 'Particuliers', slug: 'particuliers', categorie: 'usager' } }
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
      [api_qf, Solution.create!(nom: 'API Entreprise', categorie: 'api')].each { |solution| Recommandation.create!(demarche: aides, solution:) }
      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme', demarches: [aides])
      expect(confirmation("/admin/demarches/#{aides.id}/edit"))
        .to eq('Supprimer « Aides » ? 2 recommandations seront supprimées. 1 intégration en sera détachée.')
    end

    it 'compte les recommandations et intégrations d’une solution, n’annonce rien quand rien ne part' do
      Recommandation.create!(demarche: aides, solution: api_qf)
      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'consomme')
      expect(confirmation("/admin/solutions/#{api_qf.id}/edit"))
        .to eq('Supprimer « API QF » ? 1 recommandation sera supprimée. 1 intégration sera supprimée.')
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
      expect(response.body).to include('Categorie doit être rempli')
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
      expect(response.body).to include('Type integration doit être rempli')
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
      expect(response).to redirect_to('/admin/solutions')
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
      expect(response.body).to include('Statut doit être choisi dans la liste')
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
      expect(response.body).to include('<span class="fr-hint-text">Minuscules sans accent, chiffres et tirets, ex. : cantine-scolaire</span>')

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

  describe 'image de solution' do
    it 'attache le fichier envoyé par le formulaire' do
      sign_in admin
      image = Rack::Test::UploadedFile.new(StringIO.new('img'), 'image/png', original_filename: 'swagger.png')
      post '/admin/solutions', params: { solution: { nom: 'Bouquet', image: } }
      expect(response).to redirect_to('/admin/solutions')
      expect(Solution.last.image).to be_attached
    end
  end

  describe 'colonnes tableau' do
    it 'affiche et enregistre les mots-clefs une valeur par ligne' do
      sign_in admin
      demarche = Demarche.create!(nom: 'Aides', mots_clefs: %w[aides subventions])

      get "/admin/demarches/#{demarche.id}/edit"
      expect(response.body).to include("<textarea class=\"fr-input\" rows=\"4\" name=\"demarche[mots_clefs]\" id=\"demarche_mots_clefs\">\naides\nsubventions</textarea>")

      patch "/admin/demarches/#{demarche.id}", params: { demarche: { mots_clefs: "aides\r\nprimes" } }
      expect(demarche.reload.mots_clefs).to eq(%w[aides primes])
    end
  end
end
