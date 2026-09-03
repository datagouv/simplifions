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

  describe 'GET /sitemap.xml' do
    it 'liste les pages du site et les fiches visibles du catalogue, avec leur date de modification' do
      Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true, modifie_le: Time.zone.parse('2026-08-28T10:00:00Z'))
      Demarche.create!(nom: 'Brouillon', slug: 'brouillon')
      Solution.create!(nom: 'Babily', slug: 'babily', visible: true, categorie: 'brique_logicielle')
      Solution.create!(nom: 'API Quotient familial', categorie: 'api', visible: true, uid_datagouv: 'qf')

      get '/sitemap.xml'

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/xml')
      expect(response.body).to include('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
      %w[/ /demarches /solutions /articles /about /doctrine-referencement-cas-usages /doctrine-referencement-solutions
         /niveaux-simplification /terms /accessibility /sitemap /articles/qu-est-ce-qu-une-api
         /demarches/cantine /solutions/babily].each do |chemin|
        expect(response.body).to include("<loc>http://www.example.com#{chemin}</loc>"), chemin
      end
      expect(response.body).to include("<loc>http://www.example.com/demarches/cantine</loc>\n    <lastmod>2026-08-28</lastmod>")
      expect(response.body).not_to include('brouillon')
      expect(response.body).not_to include('Quotient')

      get sitemap_path
      expect(response.body).to include('<h1>Plan du site</h1>')
    end

    it 'est déclaré dans robots.txt' do
      get '/robots.txt'

      expect(response.body).to include('Sitemap: https://simplifions.data.gouv.fr/sitemap.xml')
    end
  end
end
