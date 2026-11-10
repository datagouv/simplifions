require_relative '../harness'

DOSSIER = 'guides-mis-en-avant'.freeze
GUIDE = 'guide-base-petites-collectivites'.freeze
PHRASE = 'Vous êtes une mairie ou une petite collectivité ?'.freeze

def guides_de_l_accueil(page)
  page.visit('/')
  section = page.find('section', text: 'Nos guides pour simplifier vos démarches')
  attendus = PagesController::GUIDES_DE_L_ACCUEIL.map { |slug| [Article.find(slug).h1, "/articles/#{slug}"] }
  vus = section.all('.fr-card__title a').map { [it.text, URI(it[:href]).path] }
  raise "cartes #{vus} != #{attendus}" unless vus == attendus

  Verify.evidence(DOSSIER, page, 'accueil', "cartes=#{vus.map(&:first)}")
  section.click_link 'Voir tous les articles'
  page.assert_current_path('/articles')
end

def filtrer(page, chemin, option)
  page.visit(chemin)
  page.select option, from: 'Démarches gérées par :'
  page.click_button 'Appliquer les filtres'
  page.assert_current_path(/fournisseurs-de-service=/, url: false)
end

def guide_des_communes(page, chemin)
  filtrer(page, chemin, 'Communes et groupements de communes')
  page.assert_text PHRASE
  liste = page.find(:xpath, "//li[.//p[contains(., '#{PHRASE}')]]/..")
  resultats = liste.all(:xpath, './li').size - 1
  avant = liste.all(:xpath, "./li[.//p[contains(., '#{PHRASE}')]]/preceding-sibling::li").size
  liste.assert_selector :link, Article.find(GUIDE).h1, href: "/articles/#{GUIDE}"
  raise "guide après #{avant} résultats sur #{resultats}" unless avant == [resultats, 3].min

  Verify.evidence(DOSSIER, page, "communes#{chemin.tr('/', '-')}", "#{chemin} resultats=#{resultats} guide_apres=#{avant}")
end

def sans_guide(page)
  filtrer(page, '/demarches', 'Départements')
  page.assert_no_text PHRASE
end

def donnees_structurees(page)
  donnees = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
  donnees.values_at('@type', 'headline', 'datePublished', 'dateModified')
end

def image_de_partage(page, article)
  image = File.basename(page.find('meta[property="og:image"]', visible: false)[:content])
  image.tap { raise "og:image #{it}" unless it.start_with?(File.basename(article.image, '.*')) }
end

def partage(page)
  article = Article.find(GUIDE)
  page.visit("/articles/#{GUIDE}")
  image = image_de_partage(page, article)
  vu = donnees_structurees(page)
  attendu = ['Article', article.h1, *[article.published_on, article.updated_on].map(&:iso8601)]
  raise "JSON-LD #{vu} != #{attendu}" unless vu == attendu

  Verify.evidence(DOSSIER, page, 'partage', "og:image=#{image} json_ld=#{vu}")
end

Verify.drive(__FILE__) do |page|
  Verify.check('Home') { guides_de_l_accueil(page) }
  Verify.check("Communes, cas d'usages") { guide_des_communes(page, '/demarches') }
  Verify.check('Communes, solutions') { guide_des_communes(page, '/solutions') }
  Verify.check('Other filter') { sans_guide(page) }
  Verify.check('Sharing') { partage(page) }
  Verify.check('Proof') { raise 'aucune capture' if Dir[Verify::ROOT.join(DOSSIER, "#{Verify.browser}-*.png")].empty? }
end
