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

  describe 'listes et pages statiques' do
    it 'décrit chaque page et canonise les listes sans leurs filtres' do
      { demarches_path => 'cas d’usage', solutions_path => 'solutions', articles_path => 'API',
        about_path => 'administrations', terms_path => 'Conditions générales',
        accessibility_path => 'accessibilité', sitemap_path => 'Plan du site' }.each do |chemin, mot|
        get chemin
        expect(response.body).to match(/<meta name="description" content="[^"]*#{mot}[^"]*">/), chemin
      end

      get demarches_path(q: 'cantine', page: 2)
      expect(response.body).to include('<link rel="canonical" href="http://www.example.com/demarches">')
    end

    it 'canonise une fiche sur son URL et porte les balises Open Graph' do
      Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', visible: true, description_courte: 'Communes, simplifiez.')

      get demarche_path('cantine')

      expect(response.body).to include('<link rel="canonical" href="http://www.example.com/demarches/cantine">')
      expect(response.body).to include('<meta property="og:title" content="Cantine à 1€ — Simplifions.data.gouv.fr">')
      expect(response.body).to include('<meta property="og:description" content="Communes, simplifiez.">')
      expect(response.body).to include('<meta property="og:url" content="http://www.example.com/demarches/cantine">')
      expect(response.body).to include('<meta property="og:site_name" content="Simplifions.data.gouv.fr">')
      expect(response.body).to include('<meta property="og:locale" content="fr_FR">')
    end

    it 'donne à la page d’accueil le titre et la description du site' do
      get root_path

      expect(response.body).to include('<title>Simplifions.data.gouv.fr</title>')
      expect(response.body).to match(/<meta name="description" content="[^"]*acteurs publics[^"]*">/)
      expect(response.body).to include('<link rel="canonical" href="http://www.example.com/">')
    end
  end
end
