module IntegrationsHelper
  def sections_donnees(groupes)
    bouquets, directes = groupes.partition { |recommandee, utiles| utiles != [recommandee] }
    sections = bouquets.map { |recommandee, utiles| [recommandee.nom, utiles] }
    sections << ['Autres API et jeux de données', directes.flat_map(&:last)] if directes.any?
    sections
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
