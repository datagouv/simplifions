class Grist::ImportIntegrations < Grist::ImportStep
  FRANCE_CONNECT_NOMS = ['FranceConnect', 'API FranceConnect'].freeze

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
      integration = synchronise(Integration, gid, {
        integratrice:, integree:, type_integration: type_integration(integree),
        statut: fields['Status_de_l_integration']
      })
      integration.demarche_ids = ids('Cas_d_usages', fields['Integre_pour_les_cas_d_usages'])
    end
  end

  def type_integration(integree)
    FRANCE_CONNECT_NOMS.include?(integree.nom) ? 'authentifie' : 'consomme'
  end
end
