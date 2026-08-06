class Grist::ImportUtilites < Grist::ImportStep
  def call
    import_utiles
    import_scoping_des_fournis
  end

  private

  def import_utiles
    each_record('API_et_datasets_utiles') do |gid, fields|
      demarche = find('Cas_d_usages', fields['Cas_d_usage'], gid) || next
      solution = find('APIs_et_datasets', fields['Api_ou_dataset_utile_fourni_par_une_recommandation'], gid) || next
      utilite = Utilite.find_by(grist_id: gid) || Utilite.find_or_initialize_by(demarche:, solution:)
      utilite.update!(demarche:, solution:, grist_id: gid,
        description: fields['En_quoi_cette_API_ou_dataset_est_utile_pour_ce_cas_d_usage'], ordre: fields['Ordre'])
    end
  end

  def import_scoping_des_fournis
    each_record('API_et_datasets_fournis') do |_gid, fields|
      solution = context.index["APIs_et_datasets:#{fields['API_ou_dataset_fourni']}"] || next
      list(fields['Utile_pour_les_cas_d_usages']).each do |cas_ref|
        demarche = context.index["Cas_d_usages:#{cas_ref}"] || next
        Utilite.find_or_create_by!(demarche:, solution:)
      end
    end
  end
end
