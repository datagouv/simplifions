module ApplicationHelper
  MARKDOWN_TAGS = (Rails::HTML5::SafeListSanitizer.allowed_tags + %w[details summary table thead tbody tr th td]).freeze

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

  def libelle_avec_aide(formulaire, champ, aide, obligatoire: false)
    formulaire.label(champ, class: 'fr-label') do |libelle|
      safe_join([libelle_du_champ(libelle, obligatoire), tag.span(aide, class: 'fr-hint-text')])
    end
  end

  def libelle_obligatoire(formulaire, champ)
    formulaire.label(champ, class: 'fr-label') { |libelle| libelle_du_champ(libelle, true) }
  end

  def groupe_de_champ(formulaire, champ, groupe = 'fr-input-group', classe: nil, **attributs, &)
    messages = erreurs_du_champ(formulaire, champ)
    return tag.div(capture({}, &), class: [groupe, classe], **attributs) if messages.none?

    id = "#{formulaire.field_id(champ)}-messages"
    tag.div(class: [groupe, "#{groupe}--error", classe], **attributs) do
      safe_join([capture({ aria: { invalid: true, describedby: id } }, &), tag.div(id:, class: 'fr-messages-group', aria: { live: 'polite' }) do
        safe_join(messages.map { |message| tag.p(message, class: 'fr-message fr-message--error') })
      end])
    end
  end

  def champ_de_fiche(formulaire, champ, groupe = 'fr-input-group', &)
    solution = formulaire.object
    masque = !solution.fiche? && solution.public_send(champ).blank? &&
             !solution.will_save_change_to_attribute?(champ) && !solution.attachment_changes.key?(champ.to_s)
    groupe_de_champ(formulaire, champ, groupe, classe: ('fr-hidden' if masque),
      data: { champ_fiche: true, rempli_en_base: rempli_en_base?(solution, champ) }) do |aria|
      capture(aria.merge(disabled: masque), &)
    end
  end

  def fiche_admin(ligne)
    consultable = "Admin::#{ligne.model_name.route_key.camelize}Controller".constantize.action_methods.include?('show')
    consultable ? [:admin, ligne] : [:edit, :admin, ligne]
  end

  def lien_vers_la_fiche(ligne, nom)
    link_to 'Voir la fiche', fiche_admin(ligne), class: 'fr-link fr-link--sm', aria: { label: "Voir la fiche #{nom}" }
  end

  def lignes_pour(texte)
    lignes = Array(texte).join("\n").lines.sum { |ligne| [(ligne.chomp.length / 80.0).ceil, 1].max }
    [lignes + 2, 6].max
  end

  def id_du_champ(formulaire, attribut) = formulaire.field_id(champ_de_l_erreur(formulaire.object, attribut))

  def options_traduites(modele, enum)
    modele.defined_enums.fetch(enum.to_s).keys.map { |cle| [modele.human_attribute_name("#{enum}.#{cle}"), cle] }
  end

  def page_et_pages(total, page, par_page)
    pages = [(total / par_page.to_f).ceil, 1].max
    [page.to_i.clamp(1, pages), pages]
  end

  def rafraichissement_en_cours?(passage) = passage.present? && !passage.finished? && !passage.failed?

  # Contenu Grist semi-confiance : HTML brut autorisé, nettoyé par la liste blanche Rails (ni script, ni on*, ni javascript:/data:)
  def markdown(texte)
    return '' if texte.blank?

    html = Commonmarker.to_html(texte, options: { render: { unsafe: true }, extension: { header_ids: nil } })
    sanitize(html, tags: MARKDOWN_TAGS)
  end

  private

  def rempli_en_base?(objet, champ) = (true if objet.attribute_in_database(champ).present?)

  def libelle_du_champ(libelle, obligatoire) = obligatoire ? "#{libelle.translation} (obligatoire)" : libelle.translation

  def erreurs_du_champ(formulaire, champ)
    objet = formulaire.object
    objet.errors.select { |erreur| champ_de_l_erreur(objet, erreur.attribute) == champ.to_s }.map(&:full_message)
  end

  def champ_de_l_erreur(objet, attribut) = (objet.class.reflect_on_association(attribut)&.foreign_key || attribut).to_s

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
