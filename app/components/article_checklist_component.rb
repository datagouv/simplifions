class ArticleChecklistComponent < ApplicationComponent
  def call
    tag.ul(content, class: 'checklist fr-p-0 fr-m-0', role: 'list')
  end
end
