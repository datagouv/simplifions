class Grist::ImportRecommandations < Grist::ImportStep
  def call
    each_record('Recommandations') do |gid, fields|
      demarche = find('Cas_d_usages', fields['Cas_d_usage'], gid) || next
      solution = cible(gid, fields) || next
      synchronise(Recommandation, gid, {
        demarche:, solution:,
        donnees_utiles: fields['Donnees_utiles_disponibles'],
        parametres_a_saisir: fields['Parametres_a_saisir_pour_recuperer_les_donnees'],
        url_demande_acces: fields['URL_demande_d_acces_cas_usage'],
        visible: fields['Visible_sur_simplifions'] == true, modifie_le: time_at(fields['Modifie_le'])
      })
    end
  end

  private

  def cible(gid, fields)
    if fields['Solution_recommandee'].to_i.positive?
      find('Solutions', fields['Solution_recommandee'], gid)
    else
      find('APIs_et_datasets', fields['API_ou_datasets_recommandes'], gid)
    end
  end
end
