module Admin::DashboardHelper
  LISTE = { words_connector: ', ', two_words_connector: ' et ', last_word_connector: ' et ' }.freeze

  def resume_du_brouillon(fiche)
    [champs_modifies(fiche), *recommandations_du_brouillon(fiche)].compact.join(', ')
  end

  private

  def champs_modifies(fiche)
    champs = fiche.champs_du_brouillon
    return if champs.empty?

    libelles = champs.map { libelle_du_champ(fiche.class, it) }
    "#{[libelles.first, *libelles.drop(1).map { en_minuscule(it) }].to_sentence(**LISTE)} #{accord_de_modifie(fiche.class, champs)}"
  end

  def accord_de_modifie(modele, champs)
    genre = champs.all? { it.in?(t('admin.champs_feminins')) } ? 'feminin' : 'masculin'
    pluriel = champs.size > 1 || modele.liaisons_du_brouillon.key?(champs.first) || champs.first.in?(t('admin.champs_pluriels'))
    t("admin.modifies.#{genre}", count: pluriel ? 2 : 1)
  end

  def en_minuscule(libelle) = libelle.match?(/\A.\p{Lower}/) ? libelle.downcase_first : libelle

  def recommandations_du_brouillon(fiche)
    return [] unless fiche.respond_to?(:recommandations_en_brouillon)

    fiche.recommandations_en_brouillon.group_by { [it.brouillon.fetch('niveau', it.niveau), it.brouillon['visible'] == '1' ? 'ajoutees' : 'modifiees'] }
      .sort_by { |(niveau, etat), _| [niveau == 'niveau_2' ? 0 : 1, etat] }
      .map { |(niveau, etat), recommandations| t("admin.recommandations_du_brouillon.#{niveau}.#{etat}", count: recommandations.size) }
  end

  def libelle_du_champ(modele, champ)
    liaison = modele.liaisons_du_brouillon[champ]
    return liaison.klass.model_name.human(count: 2) if liaison

    t("admin.libelles_du_brouillon.#{champ}", default: modele.human_attribute_name(champ))
  end
end
