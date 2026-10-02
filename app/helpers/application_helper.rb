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

  # Contenu Grist semi-confiance : HTML brut autorisé, nettoyé par la liste blanche Rails (ni script, ni on*, ni javascript:/data:)
  def markdown(texte)
    return '' if texte.blank?

    html = Commonmarker.to_html(texte, options: { render: { unsafe: true }, extension: { header_ids: nil } })
    sanitize(html, tags: MARKDOWN_TAGS)
  end
end
