module ArticlesHelper
  def solution_card(slug, **retouches)
    solution = fiche_citee(Solution, 'solution', slug)
    SolutionCardComponent.pour(solution, description: nil, acteurs: nil, **retouches) if solution
  end

  def demarche_card(slug, **retouches)
    demarche = fiche_citee(Demarche, 'démarche', slug)
    DemarcheCardComponent.pour(demarche, description: nil, **retouches) if demarche
  end

  def donnees_structurees(article, url:, description:, image:)
    {
      '@context': 'https://schema.org', '@type': 'Article', headline: article.h1, description:, image:,
      datePublished: article.published_on&.iso8601, dateModified: article.updated_on&.iso8601,
      mainEntityOfPage: url, inLanguage: 'fr-FR',
      publisher: { '@type': 'Organization', name: 'Simplifions.data.gouv.fr', url: root_url }
    }.compact
  end

  private

  def fiche_citee(modele, nature, slug)
    fiche = modele.find_by(slug:)
    Sentry.capture_message("Article : #{nature} citée introuvable (#{slug})") unless fiche
    fiche if fiche&.visible?
  end
end
