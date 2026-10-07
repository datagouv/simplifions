require 'rails_helper'

RSpec.describe 'Historique des fiches' do
  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }

  before { sign_in admin }

  it 'note l’admin connecté comme auteur d’une modification' do
    demarche = Demarche.create!(nom: 'Aides')

    patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }

    expect(demarche.versions.last.whodunnit).to eq(admin.id.to_s)
  end
end
