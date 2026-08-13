class Grist::ImportRecommandations < Grist::ImportStep
  def call
    import_recommandations
    import_utiles
    import_scoping_des_fournis
  end

  private

  def import_recommandations
    each_record('Recommandations') do |gid, fields|
      demarche = find('Cas_d_usages', fields['Cas_d_usage'], gid) || next
      solution = cible(gid, fields) || next
      synchronise(Recommandation, gid, {
        demarche:, solution:, niveau: :niveau_2,
        donnees_utiles: fields['Donnees_utiles_disponibles'],
        parametres_a_saisir: fields['Parametres_a_saisir_pour_recuperer_les_donnees'],
        url_demande_acces: fields['URL_demande_d_acces_cas_usage'],
        visible: fields['Visible_sur_simplifions'] == true, modifie_le: time_at(fields['Modifie_le'])
      }, also_by: { demarche:, solution: })
    end
  end

  def import_utiles
    each_record('API_et_datasets_utiles') do |gid, fields|
      demarche = find('Cas_d_usages', fields['Cas_d_usage'], gid) || next
      solution = find('APIs_et_datasets', fields['Api_ou_dataset_utile_fourni_par_une_recommandation'], gid) || next
      synchronise(Recommandation, gid, {
        demarche:, solution:, niveau: :niveau_1,
        description: fields['En_quoi_cette_API_ou_dataset_est_utile_pour_ce_cas_d_usage'], ordre: fields['Ordre']
      }, also_by: { demarche:, solution: })
    end
  end

  def import_scoping_des_fournis
    each_record('API_et_datasets_fournis') do |gid, fields|
      solution = context.index["APIs_et_datasets:#{fields['API_ou_dataset_fourni']}"] || next
      Demarche.where(id: ids('Cas_d_usages', fields['Utile_pour_les_cas_d_usages'], gid)).find_each do |demarche|
        seen(Recommandation.find_or_create_by!(demarche:, solution:) { |reco| reco.niveau = :niveau_1 })
      rescue ActiveRecord::RecordInvalid => e
        quarantine(gid, e.message)
      end
    end
  end

  def cible(gid, fields)
    if fields['Solution_recommandee'].to_i.positive?
      find('Solutions', fields['Solution_recommandee'], gid)
    else
      find('APIs_et_datasets', fields['API_ou_datasets_recommandes'], gid)
    end
  end
end
