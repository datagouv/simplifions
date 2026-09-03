require 'rails_helper'

RSpec.describe 'SEO' do
  describe 'fiches' do
    it 'titre et décrit un cas d’usage avec son nom et la première ligne de son chapo' do
      Demarche.create!(nom: 'Cantine à 1€', icone: '🥣', slug: 'cantine', visible: true,
        description_courte: "Communes, simplifiez.\nDeuxième ligne ignorée.")

      get demarche_path('cantine')

      expect(response.body).to include('<title>Cantine à 1€ — Simplifions.data.gouv.fr</title>')
      expect(response.body).to include('<meta name="description" content="Communes, simplifiez.">')
    end

    it 'titre et décrit une solution, avec son image comme visuel de partage' do
      solution = Solution.create!(nom: 'Babily', slug: 'babily', visible: true, categorie: 'brique_logicielle',
        description_courte: 'Crèches, calculez le tarif.')
      solution.image.attach(io: StringIO.new('png'), filename: 'babily.png', content_type: 'image/png')

      get solution_path('babily')

      expect(response.body).to include('<title>Babily — Simplifions.data.gouv.fr</title>')
      expect(response.body).to include('<meta name="description" content="Crèches, calculez le tarif.">')
      expect(response.body).to match(%r{<meta property="og:image" content="http://www\.example\.com/rails/active_storage/[^"]+/babily\.png">})
    end
  end
end
