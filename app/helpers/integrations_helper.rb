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
end
