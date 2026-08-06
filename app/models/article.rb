Article = Data.define(:slug, :h1, :title, :description, :image, :keywords, :hero_backdrop_gradient, :sections)

class Article
  KEYWORD_CATEGORIES = {
    "Type d'article" => ['Guide de base', 'Guide métier', 'Guide technique', 'Définition'],
    'Type de données' => ['API', 'Jeux de données'],
    'Vous êtes ...' => ['Petite collectivité', 'DSI', 'MOA', 'Éditeur de logiciels'],
    'Thématique' => ['Parcours usager', 'Intégration technique', 'API FranceConnectées']
  }.freeze

  def self.all
    ALL
  end

  def self.find(slug)
    ALL.find { |article| article.slug == slug }
  end

  def self.filtered(selected_keywords)
    ALL.select { |article| article.matches?(selected_keywords) }
  end

  def initialize(image: nil, **attrs)
    super
  end

  # Un article matche s'il porte au moins un mot-clef sélectionné dans chaque
  # catégorie où une sélection existe (même logique que l'ancien site).
  def matches?(selected_keywords, except_category: nil)
    KEYWORD_CATEGORIES.all? do |category, category_keywords|
      next true if category == except_category

      selection = selected_keywords & category_keywords
      selection.empty? || keywords.intersect?(selection)
    end
  end

  def keywords_in(category)
    keywords & KEYWORD_CATEGORIES.fetch(category)
  end

  def audience
    keywords_in('Vous êtes ...')
  end

  def template
    "articles/#{slug.tr('-', '_')}"
  end

  # Un fichier YAML par article dans config/articles/, le préfixe numérique
  # des noms de fichiers donne l'ordre d'affichage.
  ALL = Rails.root.glob('config/articles/*.yml')
    .map { |path| new(**YAML.load_file(path).transform_keys(&:to_sym)) }
    .freeze
end
