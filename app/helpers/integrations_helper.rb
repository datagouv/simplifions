module IntegrationsHelper
  def couleur_integration(integrees, utiles)
    pourcentage = integrees * 100 / utiles
    if pourcentage >= 75 then 'green'
    elsif pourcentage >= 50 then 'yellow'
    elsif pourcentage >= 25 then 'orange'
    else 'red'
    end
  end

  def titre_groupe_donnees(bouquet) = bouquet || t('public.autres_donnees_utiles')

  def colonne_de_la_liste(liste) = liste == :integratrices ? :integratrice : :integree
  def colonne_fixe_de_la_liste(liste) = liste == :integratrices ? :integree : :integratrice

  def ligne_vide(liste, solution_id)
    Integration.new("#{colonne_fixe_de_la_liste(liste)}_id": solution_id, type_integration: { fournies: 'expose', integrees: 'consomme' }[liste])
  end
end
