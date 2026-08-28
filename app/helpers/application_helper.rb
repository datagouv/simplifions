module ApplicationHelper
  # Contenu Grist semi-confiance : unsafe: false échappe le HTML brut et les URLs javascript:/data:
  def markdown(texte)
    return '' if texte.blank?

    Commonmarker.to_html(texte, options: { render: { unsafe: false } }).html_safe # rubocop:disable Rails/OutputSafety
  end
end
