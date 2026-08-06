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
      synchronise(Utilite, gid, {
        demarche:, solution:,
        description: fields['En_quoi_cette_API_ou_dataset_est_utile_pour_ce_cas_d_usage'], ordre: fields['Ordre']
      }, also_by: { demarche:, solution: })
    end
  end

  def import_scoping_des_fournis
    each_record('API_et_datasets_fournis') do |gid, fields|
      solution = context.index["APIs_et_datasets:#{fields['API_ou_dataset_fourni']}"] || next
      Demarche.where(id: ids('Cas_d_usages', fields['Utile_pour_les_cas_d_usages'], gid)).find_each do |demarche|
        seen(Utilite.find_or_create_by!(demarche:, solution:))
      end
    end
  end
end
