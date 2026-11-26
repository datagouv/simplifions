require 'rails_helper'

RSpec.describe 'Organisation ajoutée depuis la fiche solution' do
  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }

  before do
    Organisation.create!(nom: 'DINUM')
    sign_in admin
  end

  def page = response.parsed_body
  def fenetre = page.at_css('dialog#fenetre-nouvelle-organisation')
  def message_sous_la_liste = page.at_css('#organisation-absente').text.squish
  def flux(action, cible) = Nokogiri::HTML5.fragment(response.body).css("turbo-stream[action=#{action}][target='#{cible}'] template")

  def creer(nom, public_ou_prive: 'Public')
    post '/admin/organisations', params: { sur_place: 1, organisation: { nom:, nom_long: '', public_ou_prive: } }, as: :turbo_stream
  end

  describe 'fiche solution' do
    it 'propose d’ajouter une organisation dans une fenêtre, sous la liste Organisations' do
      get "/admin/solutions/#{Solution.create!(nom: 'API QF', categorie: 'api').id}/edit"
      bouton = page.at_css('fieldset:has(> legend) ~ div button[aria-controls=fenetre-nouvelle-organisation]')
      expect(bouton.text.squish).to eq('Ajouter une organisation')
      expect(fenetre.at_css('form')['action']).to eq('/admin/organisations')
      expect(fenetre.css('form [name^="organisation["]').pluck('name').uniq).to eq(%w[organisation[nom] organisation[nom_long] organisation[public_ou_prive]])
      expect(fenetre.ancestors('form#formulaire-fiche')).to be_empty
      expect(message_sous_la_liste).to eq('')
    end

    it 'signale sous la liste l’organisation de data.gouv.fr absente, et préremplit la fenêtre avec son nom' do
      api = Solution.create!(nom: 'API Melodi', categorie: 'api', uid_datagouv: '6661e09c7230a8fc3b1ec229', datagouv_titre: 'API Melodi', datagouv_organisation: 'Insee')
      get "/admin/solutions/#{api.id}/edit"
      expect(message_sous_la_liste).to eq('data.gouv.fr indique l’organisation « Insee », absente de la liste Organisations.')
      expect(fenetre.at_css('input[name="organisation[nom]"]')['value']).to eq('Insee')
      bloc = page.at_css('turbo-frame#repris-datagouv').text.squish
      expect(bloc).to include('Organisation : Insee')
      expect(bloc).not_to include('absente')
    end

    it 'ne signale rien quand l’organisation de data.gouv.fr est dans la liste' do
      api = Solution.create!(nom: 'API Sirene', categorie: 'api', uid_datagouv: '672cf6aece89cb14e31f0fba', datagouv_titre: 'API Sirene', datagouv_organisation: 'dinum')
      get "/admin/solutions/#{api.id}/edit"
      expect(message_sous_la_liste).to eq('')
      expect(fenetre.at_css('input[name="organisation[nom]"]')['value']).to be_nil
    end
  end

  describe 'enregistrement depuis la fenêtre' do
    it 'crée l’organisation, la coche dans la liste et dit d’enregistrer la fiche' do
      expect { creer('Insee') }.to change(Organisation, :count).by(1)
      insee = Organisation.find_by!(nom: 'Insee')
      expect(insee.public_ou_prive).to eq('Public')
      expect(response).to have_http_status(:ok)

      case_ajoutee = flux(:append, 'solution_organisation_ids_cases').at_css('input[type=checkbox]')
      expect(case_ajoutee.attributes.slice('name', 'value', 'checked').transform_values(&:value))
        .to eq('name' => 'solution[organisation_ids][]', 'value' => insee.id.to_s, 'checked' => 'checked')
      expect(flux(:append, 'solution_organisation_ids_cases').text.squish).to include('Insee', 'Voir la fiche')
      expect(flux(:update, 'organisation-absente').text.squish)
        .to eq('« Insee » ajoutée à la liste Organisations et cochée : enregistrez la fiche pour la garder.')
      nouvelle_fenetre = flux(:replace, 'fenetre-nouvelle-organisation').at_css('dialog')
      expect(nouvelle_fenetre.at_css('input[name="organisation[nom]"]')['value']).to be_nil
      expect(nouvelle_fenetre['data-controller']).to be_nil
    end

    it 'garde la fenêtre ouverte avec l’erreur quand le nom manque, sans rien créer' do
      expect { creer('') }.not_to change(Organisation, :count)
      expect(response).to have_http_status(:unprocessable_content)
      nouvelle_fenetre = flux(:replace, 'fenetre-nouvelle-organisation').at_css('dialog')
      expect(nouvelle_fenetre['data-controller']).to eq('fenetre-rouverte')
      expect(nouvelle_fenetre.text.squish).to include('Nom doit être rempli')
      expect(flux(:append, 'solution_organisation_ids_cases')).to be_empty
    end

    it 'garde la page Organisations comme avant hors de la fenêtre' do
      post '/admin/organisations', params: { organisation: { nom: 'Insee' } }
      expect(response).to redirect_to(%r{/admin/organisations/\d+/edit})
    end
  end
end
