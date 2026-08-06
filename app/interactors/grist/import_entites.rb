class Grist::ImportEntites < Grist::ImportStep
  CATEGORIES_SOLUTION = {
    'Brique technique' => 'brique_logicielle',
    'Logiciel métier' => 'logiciel_metier_cle_en_main',
    'Portail de consultation' => 'site_de_consultation'
  }.freeze
  TYPES_API = { 'API' => 'api', 'Jeu de données' => 'base_de_donnees' }.freeze

  def call
    import_organisations
    import_types_acteurs
    import_vocabulaires
    import_demarches
    import_solutions
    import_apis_et_datasets
  end

  private

  def import_organisations
    each_record('Operateurs') do |gid, fields|
      synchronise(Organisation, gid, {
        nom: fields['Nom'], nom_long: fields['Nom_long'], public_ou_prive: fields['Public_ou_prive'],
        type_organisation_privee: fields['Type_d_organisation_privee'], site_internet: fields['Site_internet']
      })
    end
  end

  def import_types_acteurs
    each_record('Fournisseurs_de_services') do |gid, fields|
      synchronise(TypeActeur, gid, {
        nom: fields['Label'], description: fields['Ce_que_cela_inclut'],
        codes_juridiques: fields['Codes_juridiques'], slug: list(fields['slugs']).first
      })
    end
  end

  def import_vocabulaires
    each_record('Usagers') do |gid, fields|
      synchronise(Vocabulaire, gid, { nom: fields['Label'], slug: fields['slug'], categorie: 'usager' })
    end
    each_record('Types_de_simplification') do |gid, fields|
      synchronise(Vocabulaire, gid, { nom: fields['Label'], slug: fields['slug'], categorie: 'type_simplification' })
    end
  end

  def import_demarches
    each_record('Cas_d_usages') do |gid, fields|
      demarche = synchronise(Demarche, gid, demarche_attributes(fields))
      demarche.vocabulaire_ids = ids('Usagers', fields['Pour_simplifier_les_demarches_de'])
      demarche.type_acteur_ids = ids('Fournisseurs_de_services', fields['A_destination_de'])
    end
  end

  def demarche_attributes(fields)
    {
      nom: fields['Nom'], icone: fields['Icone_du_titre'], description_courte: fields['Description_courte'],
      contexte: fields['Contexte'], cadre_juridique: fields['Cadre_juridique'],
      mots_clefs: list(fields['Mots_clefs']),
      visible: fields['Visible_sur_simplifions'] == true, modifie_le: time_at(fields['Modifie_le'])
    }
  end

  def import_solutions
    each_record('Solutions') do |gid, fields|
      solution = synchronise(Solution, gid, solution_attributes(gid, fields))
      solution.organisation_ids = ids('Operateurs', fields['Operateur'])
      solution.vocabulaire_ids = ids('Usagers', fields['Pour_simplifier_les_demarches_de']) +
                                 ids('Types_de_simplification', fields['Types_de_simplification'])
      solution.type_acteur_ids = ids('Fournisseurs_de_services', fields['A_destination_de'])
    end
  end

  def solution_attributes(gid, fields)
    {
      nom: fields['Nom'], description_courte: fields['Description_courte'], site_internet: fields['Site_internet'],
      permet: fields['Cette_solution_permet'], ne_permet_pas: fields['Cette_solution_ne_permet_pas'],
      legende_image: fields['Legende_de_l_image'], url_demande_acces: fields['URL_demande_d_acces'],
      uid_datagouv: fields['UID_datagouv'], categorie: categorie_solution(gid, fields['Categorie_de_solution']),
      visible: fields['Visible_sur_simplifions'] == true, modifie_le: time_at(fields['Modifie_le'])
    }
  end

  def import_apis_et_datasets
    each_record('APIs_et_datasets') do |gid, fields|
      categorie = TYPES_API[fields['Type']]
      note("#{gid} — type non mappé : #{fields['Type']}") if categorie.nil? && fields['Type'].present?
      synchronise(Solution, gid, {
        nom: fields['Nom'], uid_datagouv: fields['UID_datagouv'],
        france_connectee: fields['API_FranceConnectee'] == true, categorie:,
        visible: fields['Visible_sur_simplifions'] == true, modifie_le: time_at(fields['Modifie_le'])
      })
    end
  end

  def categorie_solution(gid, reflist)
    refs = list(reflist)
    note("#{gid} — plusieurs catégories, première retenue") if refs.size > 1
    nom = categories_nom[refs.first]
    return if nom.nil?

    categorie = CATEGORIES_SOLUTION[nom]
    note("#{gid} — catégorie non mappée : #{nom}") if categorie.nil?
    categorie
  end

  def categories_nom
    @categories_nom ||= context.tables.fetch('Categories_de_solution')
      .to_h { |record| [record['id'], record['fields']['Nom']] }
  end
end
