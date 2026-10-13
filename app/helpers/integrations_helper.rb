module IntegrationsHelper
  def sections_donnees(groupes)
    bouquets, directes = groupes.partition { |recommandee, utiles| utiles != [recommandee] }
    sections = bouquets.map { |recommandee, utiles| [recommandee.nom, utiles] }
    sections << ['Autres API et jeux de données', directes.flat_map(&:last)] if directes.any?
    sections
  end

  BADGES_SOLUTIONS = { 'brique_logicielle' => %w[fr-icon-code-box-fill brique briques],
                       'logiciel_metier_cle_en_main' => %w[fr-icon-mac-fill logiciel logiciels],
                       'site_de_consultation' => %w[fr-icon-seo-fill site sites] }.freeze

  def filtre_affichage(categorie) = categorie == 'brique_logicielle' ? 'api' : categorie

  def badge_nombre_solutions(categorie, nombre)
    icone, singulier, pluriel = BADGES_SOLUTIONS.fetch(categorie)
    tag.span("#{nombre} #{nombre > 1 ? pluriel : singulier}", data: { compte: categorie, singulier:, pluriel: },
      class: "fr-badge fr-badge--sm fr-badge--icon-left fr-background-contrast--info fr-text-default--info fr-ml-1w #{icone}")
  end

  def couleur_integration(integrees, utiles)
    pourcentage = integrees * 100 / utiles
    if pourcentage >= 75 then 'green'
    elsif pourcentage >= 50 then 'yellow'
    elsif pourcentage >= 25 then 'orange'
    else 'red'
    end
  end
end
