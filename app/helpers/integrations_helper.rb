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

  ONGLETS_D_INTEGRATIONS = { fournies: 'api-fournies', integrees: 'api-integrees', integratrices: 'integratrices' }.freeze

  def libelles_des_onglets_d_integrations(solution)
    solution.nombres_d_integrations.to_h do |liste, nombre|
      [ONGLETS_D_INTEGRATIONS.fetch(liste), "#{t("admin.integrations_de_la_solution.#{liste}")} (#{nombre})"]
    end
  end

  def colonne_de_la_liste(liste) = liste == :integratrices ? :integratrice : :integree
  def colonne_fixe_de_la_liste(liste) = liste == :integratrices ? :integree : :integratrice

  def ligne_vide(liste, solution_id)
    Integration.new("#{colonne_fixe_de_la_liste(liste)}_id": solution_id, type_integration: Integration::TYPE_DE_LISTE[liste.to_s])
  end

  def lignes_d_integrations(solution, liste)
    integrations = {
      fournies: solution.integrations_qu_elle_expose.dans_l_ordre_public,
      integrees: solution.integrations_comme_integratrice.consomme.par_libelle_admin_de(:integree),
      integratrices: solution.integrations_comme_integree.par_libelle_admin_de(:integratrice)
    }.fetch(liste)
    [*integrations.preload(colonne_de_la_liste(liste)), ligne_vide(liste, solution.id)]
  end

  def sens_du_focus(sens, rang, nombre)
    return 'descendre' if sens == 'monter' && rang == 1
    return 'monter' if sens == 'descendre' && rang == nombre

    sens
  end
end
