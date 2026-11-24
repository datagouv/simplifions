require 'rails_helper'

RSpec.describe 'Slug verrouillé dans les fiches' do
  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }

  before { sign_in admin }

  def page = response.parsed_body
  def slug(modele) = page.at_css("input[name='#{modele}[slug]']")
  def bouton_modifier = page.css('button').find { it.text.squish == 'Modifier le slug' }

  it 'grise le slug d’une démarche, à la création comme à la modification, avec un bouton pour le modifier' do
    get '/admin/demarches/new'
    expect(slug(:demarche)['disabled']).to be_present
    expect(bouton_modifier).to be_present

    aides = Demarche.create!(nom: 'Aides', slug: 'aides', visible: true)
    get "/admin/demarches/#{aides.id}/edit"
    expect(slug(:demarche)['disabled']).to be_present
    expect(slug(:demarche)['value']).to eq('aides')
    expect(bouton_modifier).to be_present

    aides.enregistrer('slug' => 'aides-sociales')
    get "/admin/demarches/#{aides.id}/edit"
    expect(slug(:demarche)['disabled']).to be_present
    expect(slug(:demarche)['value']).to eq('aides-sociales')
  end

  it 'grise le slug d’une solution, à la création comme à la modification, avec un bouton pour le modifier' do
    get '/admin/solutions/new'
    expect(slug(:solution)['disabled']).to be_present
    expect(bouton_modifier).to be_present

    annuaire = Solution.create!(nom: 'Annuaire', categorie: 'site_de_consultation', slug: 'annuaire', visible: true)
    get "/admin/solutions/#{annuaire.id}/edit"
    expect(slug(:solution)['disabled']).to be_present
    expect(slug(:solution)['value']).to eq('annuaire')
  end

  it 'garde le slug quand la fiche est enregistrée sans lui' do
    annuaire = Solution.create!(nom: 'Annuaire', categorie: 'site_de_consultation', slug: 'annuaire')
    patch "/admin/solutions/#{annuaire.id}", params: { solution: { nom: 'Annuaire des services' } }
    expect(annuaire.reload).to have_attributes(nom: 'Annuaire des services', slug: 'annuaire')

    post '/admin/demarches', params: { demarche: { nom: 'Cantine scolaire' } }
    expect(Demarche.find_by(nom: 'Cantine scolaire').slug).to eq('cantine-scolaire')
  end

  it 'laisse le slug ouvert, avec la saisie, quand elle est refusée' do
    post '/admin/demarches', params: { demarche: { nom: 'Cantine', slug: 'Cantine Scolaire' } }
    expect(slug(:demarche)['disabled']).to be_nil
    expect(slug(:demarche)['value']).to eq('Cantine Scolaire')
    expect(bouton_modifier).to be_nil

    aides = Demarche.create!(nom: 'Aides', slug: 'aides', visible: true)
    patch "/admin/demarches/#{aides.id}", params: { demarche: { slug: 'Aides Sociales', visible: '1' } }
    expect(slug(:demarche)['disabled']).to be_nil
    expect(slug(:demarche)['value']).to eq('Aides Sociales')
  end

  it 'garde le slug grisé quand la saisie est refusée sans qu’il ait changé' do
    post '/admin/demarches', params: { demarche: { nom: '' } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(slug(:demarche)['disabled']).to be_present
    expect(bouton_modifier).to be_present
  end
end
