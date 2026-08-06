class ArticleReadMoreComponent < ApplicationComponent
  def initialize(href:, title:, description: nil)
    @href = href
    @title = title
    @description = description
  end
end
