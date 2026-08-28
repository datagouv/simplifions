module ApplicationHelper
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

  # Contenu Grist semi-confiance : unsafe: false échappe le HTML brut et les URLs javascript:/data:
  def markdown(texte)
    return '' if texte.blank?

    Commonmarker.to_html(texte, options: { render: { unsafe: false } }).html_safe # rubocop:disable Rails/OutputSafety
  end
end
