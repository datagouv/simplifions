require 'rails_helper'

RSpec.describe 'Dépôt de fichiers' do
  def depot_direct
    blob = { filename: 'piege.png', byte_size: 3, checksum: Digest::MD5.base64digest('img'), content_type: 'image/png' }
    expect { post '/rails/active_storage/direct_uploads', params: { blob: }, as: :json }
      .not_to change(ActiveStorage::Blob, :count)
    response
  end

  it 'refuse le dépôt direct à un visiteur comme à un admin connecté' do
    expect(depot_direct).to have_http_status(:not_found)
    sign_in Admin.create!(email: 'admin@simplifions.local', password: 'mot-de-passe-solide')
    expect(depot_direct).to have_http_status(:not_found)
  end

  it 'laisse l’image d’une solution lisible par tous' do
    solution = Solution.create!(nom: 'Bouquet')
    solution.image.attach(io: StringIO.new('img'), filename: 'bouquet.png', content_type: 'image/png')
    get rails_blob_path(solution.image)
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('img')
  end
end
