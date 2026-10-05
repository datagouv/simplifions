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

  def rafraichissement_en_cours?(passage) = passage.present? && !passage.finished? && !passage.failed?

  # Contenu Grist semi-confiance : HTML brut autorisé, nettoyé par la liste blanche Rails (ni script, ni on*, ni javascript:/data:)
  def markdown(texte)
    return '' if texte.blank?

    html = Commonmarker.to_html(texte, options: { render: { unsafe: true }, extension: { header_ids: nil } })
    sanitize(html, tags: MARKDOWN_TAGS)
  end

  private

  def etat_du_passage(passage)
    if passage.failed?
      "échoué (#{passage.failed_execution.message})"
    elsif passage.finished?
      "terminé le #{l(passage.finished_at.in_time_zone('Europe/Paris'), format: :court)}"
    else
      'en cours'
    end
  end
end
