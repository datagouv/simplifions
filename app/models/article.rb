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

  ALL = [
    new(
      slug: 'qu-est-ce-qu-une-api',
      h1: "Qu'est-ce qu'une API ?",
      title: "Qu'est-ce qu'une API ? Explication simple pour les non-techniciens",
      description: "Comprendre ce qu'est une API sans vocabulaire technique : comment ces outils permettent aux administrations d'échanger des données pour simplifier les démarches des entreprises, associations et particuliers.",
      keywords: ['API', 'Définition', 'Petite collectivité', 'MOA'],
      hero_backdrop_gradient: 'linear-gradient(135deg, #decdbd 0%, #d2e2f6 100%)',
      sections: {
        'definition' => "Qu'est-ce qu'une API ?",
        'administration' => 'API et Dîtes-le nous une fois',
        'demonstrateur' => 'Démonstrateur',
        'donnees-utilisees-par-l-api' => "Données utilisées par l'API",
        'api-entreprise-particulier' => 'Les API clés pour la simplification',
        'recapitulatif' => 'Récapitulatif'
      }
    ),
    new(
      slug: 'apis-franceconnectees',
      h1: 'Les API FranceConnectées',
      title: 'Administrations, pré-remplissez les démarches FranceConnectées',
      description: "Les API FranceConnectées donnent accès à diverses données administratives des particuliers en proposant FranceConnect comme modalité d'appel. Elles permettent de simplifier les démarches d'un particulier utilisant FranceConnect en récupérant automatiquement d'autres informations administratives le concernant.",
      keywords: ['API', 'Guide métier', 'API FranceConnectées', 'DSI', 'MOA', 'Éditeur de logiciels', 'Définition'],
      hero_backdrop_gradient: 'linear-gradient(135deg, #a19237 0%, #fddede 100%)',
      sections: {
        'definition' => 'Définition',
        'acteurs' => 'Acteurs',
        'possibilite-de-simplification' => 'Possibilités de simplification',
        'liste-des-api-franceconnectees' => 'Liste des API FranceConnectées'
      }
    ),
    new(
      slug: 'guide-base-petites-collectivites',
      h1: 'Guide de base pour les petites collectivités',
      title: 'Petites communes : un guide pour simplifier vos démarches',
      description: "Petites collectivités, simplifiez vos démarches administratives sans développement : portails publics gratuits et logiciels éditeurs déjà raccordés aux données vous permettent d'éviter de les redemander aux usagers.",
      image: 'articles/image-guide-de-base-collectivites-guichet-mairie-2.jpg',
      keywords: ['Guide de base', 'Petite collectivité'],
      hero_backdrop_gradient: 'linear-gradient(135deg, #34BAB5 0%, #d2e2f6 100%)',
      sections: {
        'definition' => 'Simplifier par la donnée, définition',
        'actions-rapides' => 'À vérifier dès maintenant',
        'sites-consultation' => 'Sites de consultation',
        'logiciels-editeurs' => 'Logiciels éditeurs',
        'demarches-faciles-a-simplifier' => 'Démarches faciles à simplifier',
        'checklist' => 'Récapitulatif',
        'cta' => 'Pour aller plus loin'
      }
    ),
    new(
      slug: 'prerequis-et-etapes-integration-api',
      h1: "Prérequis et étapes d'intégration d'une API",
      title: "Prérequis et étapes d'intégration d'une API",
      description: "Prérequis techniques, juridiques et d'usage, étapes d'intégration, limites à connaître : Acteurs publics, ce guide vous aide à comprendre ce qui vous attend lorsque vous vous engagez dans la simplification de vos démarches grâce aux API.",
      keywords: ['API', 'Guide technique', 'Guide métier', 'Intégration technique', 'DSI', 'MOA', 'Éditeur de logiciels'],
      hero_backdrop_gradient: 'linear-gradient(135deg, #decdbd 0%, #a3afce 100%)',
      sections: {
        'prerequis' => 'Prérequis',
        'etapes-integration' => "Étapes d'intégration",
        'limites' => 'Limites des API',
        'recapitulatif' => 'Pour résumer'
      }
    ),
    new(
      slug: 'vos-interlocuteurs-selon-le-type-d-api',
      h1: "Vos interlocuteurs selon le type d'API",
      title: "Vos interlocuteurs selon le type d'API",
      description: "Identifiez votre interlocuteur selon le type d'API que vous intégrez et selon votre situation.",
      keywords: ['API', 'Guide métier', 'DSI', 'MOA', 'Éditeur de logiciels'],
      hero_backdrop_gradient: 'linear-gradient(135deg, #decdbd 0%, #e3e3fd 100%)',
      sections: {
        'types-api' => "Types d'API",
        'interlocuteurs' => 'Acteurs et interlocuteurs',
        'recapitulatif' => 'Pour résumer'
      }
    ),
    new(
      slug: 'anticiper-le-parcours-usager-avant-d-integrer-vos-api',
      h1: "Anticiper le parcours usager avant d'intégrer vos API",
      title: "Anticiper le parcours usager avant d'intégrer vos API",
      description: 'API délivrant des données publiques ou protégées : ce guide détaille les parcours usager possibles pour intégrer une API.',
      keywords: ['API', 'Parcours usager', 'Guide métier', 'DSI', 'MOA', 'Éditeur de logiciels'],
      hero_backdrop_gradient: 'linear-gradient(135deg, #decdbd 0%, #cfe0ef 100%)',
      sections: {
        'parcours-donnees-publiques' => 'Parcours avec données publiques',
        'parcours-donnees-protegees' => 'Parcours avec données protégées',
        'parcours-alternatifs' => 'Parcours alternatifs',
        'recapitulatif' => 'Pour résumer'
      }
    )
  ].freeze
end
