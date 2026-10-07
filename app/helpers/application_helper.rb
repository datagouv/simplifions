module ApplicationHelper
  MARKDOWN_TAGS = (Rails::HTML5::SafeListSanitizer.allowed_tags + %w[details summary table thead tbody tr th td]).freeze
  EVENEMENTS = { 'create' => 'Création', 'update' => 'Modification', 'destroy' => 'Suppression' }.freeze

  # Liste "A, B et C" avec les éléments en gras, séparateurs en graisse normale.
  def liste_humaine(items)
    parts = []
    items.each_with_index do |item, index|
      if index.positive?
        parts << (index == items.size - 1 ? ' et ' : ', ')
      end
      parts << tag.b(item)
    end
    safe_join(parts)
  end

  def statut_rafraichissement(passage)
    return 'Aucun rafraîchissement récent.' unless passage

    "Dernier rafraîchissement : #{etat_du_passage(passage)}."
  end

  def surveille_les_modifications(objet)
    { controller: 'formulaire-modifie', formulaire_modifie_modifie_value: objet.errors.any?,
      action: 'input->formulaire-modifie#marquer change->formulaire-modifie#marquer' }
  end

  def champ_de_fiche(formulaire, champ)
    solution = formulaire.object
    masque = !solution.fiche? && solution.public_send(champ).blank? &&
             !solution.will_save_change_to_attribute?(champ) && !solution.attachment_changes.key?(champ.to_s)
    { class: ('fr-hidden' if masque), disabled: masque,
      input_group_options: { data: { champ_fiche: true, rempli_en_base: rempli_en_base?(solution, champ) } } }
  end

  def fiche_admin(ligne)
    consultable = "Admin::#{ligne.model_name.route_key.camelize}Controller".constantize.action_methods.include?('show')
    consultable ? [:admin, ligne] : [:edit, :admin, ligne]
  end

  def lien_vers_la_fiche(ligne, nom)
    link_to 'Voir la fiche', fiche_admin(ligne), class: 'fr-link fr-link--sm', aria: { label: "Voir la fiche #{nom}" }
  end

  def pagination(liste, filtres)
    gardes = [*filtres, *request.path_parameters.keys, *Kaminari::Helpers::PARAM_KEY_EXCEPT_LIST].map(&:to_s)
    paginate liste, params: (request.query_parameters.keys - gardes).index_with(nil)
  end

  def options_traduites(modele, enum)
    modele.defined_enums.fetch(enum.to_s).keys.map { |cle| [modele.human_attribute_name("#{enum}.#{cle}"), cle] }
  end

  def titre_de_version(version)
    auteur = auteur_de_version(version)
    [EVENEMENTS.fetch(version.event), ("par #{auteur}" if auteur), "le #{l(version.created_at, format: :court)}"].compact.join(' ')
  end

  def auteur_de_version(version)
    return version.whodunnit unless version.whodunnit.to_s.match?(/\A\d+\z/)

    Admin.find_by(id: version.whodunnit)&.email || 'un compte supprimé'
  end

  def champs_changes(version, modele)
    version.changeset.except('id', 'created_at', 'updated_at').reject { |_, valeurs| valeurs.all?(&:blank?) }.to_h do |champ, valeurs|
      [modele.human_attribute_name(champ), valeurs.map { |valeur| valeur_lisible(modele, champ, valeur) }]
    end
  end

  def valeur_de_version(valeur)
    case valeur
    when nil, '', [] then 'Vide'
    when true, false then valeur ? 'Oui' : 'Non'
    when Array then valeur.join(', ')
    when Time then l(valeur, format: :court)
    else safe_join(valeur.to_s.lines.map(&:chomp), tag.br)
    end
  end

  def rafraichissement_en_cours?(passage) = passage.present? && !passage.finished? && !passage.failed?

  # Contenu Grist semi-confiance : HTML brut autorisé, nettoyé par la liste blanche Rails (ni script, ni on*, ni javascript:/data:)
  def markdown(texte)
    return '' if texte.blank?

    html = Commonmarker.to_html(texte, options: { render: { unsafe: true }, extension: { header_ids: nil } })
    sanitize(html, tags: MARKDOWN_TAGS)
  end

  private

  def valeur_lisible(modele, champ, valeur)
    valeur = modele.type_for_attribute(champ).cast(valeur)
    modele.defined_enums.key?(champ) && valeur ? modele.human_attribute_name("#{champ}.#{valeur}") : valeur
  end

  def rempli_en_base?(objet, champ) = (true if objet.attribute_in_database(champ).present?)

  def etat_du_passage(passage)
    if passage.failed?
      "échoué (#{passage.failed_execution.message})"
    elsif passage.finished?
      "terminé le #{l(passage.finished_at, format: :court)}"
    else
      'en cours'
    end
  end
end
