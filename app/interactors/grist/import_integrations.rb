class Grist::ImportIntegrations < Grist::ImportStep
  def call
    import_fournis
    import_integres
  end

  private

  def import_fournis
    each_record('API_et_datasets_fournis') do |gid, fields|
      integratrice = find('Solutions', fields['Solution_fournisseur'], gid) || next
      integree = find('APIs_et_datasets', fields['API_ou_dataset_fourni'], gid) || next
      synchronise(Integration, gid, { integratrice:, integree:, type_integration: 'expose' })
    end
  end

  def import_integres
    each_record('API_et_datasets_integres') do |gid, fields|
      integratrice = find('Solutions', fields['Solution_integratrice'], gid) || next
      integree = find('APIs_et_datasets', fields['API_ou_dataset_integre'], gid) || next
      synchronise(Integration, gid, {
        integratrice:, integree:, type_integration: 'consomme',
        statut: fields['Status_de_l_integration'],
        demarches: demarches_de_l_api(integree, ids('Cas_d_usages', fields['Integre_pour_les_cas_d_usages'], gid), gid)
      })
    end
  end

  def demarches_de_l_api(integree, demarche_ids, gid)
    recommandations = Recommandation.where(id: context.seen['Recommandation'], solution: integree)
    autorisees = Demarche.where(id: recommandations.select(:demarche_id)).where(id: demarche_ids)
    Demarche.where(id: demarche_ids).where.not(id: autorisees).pluck(:nom).each do |nom|
      note("#{gid} — démarche « #{nom} » hors des démarches de l’API, écartée")
    end
    autorisees
  end
end
