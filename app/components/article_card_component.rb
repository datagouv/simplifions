class ArticleCardComponent < ApplicationComponent
  def initialize(article:, horizontal: false)
    @article = article
    @horizontal = horizontal
  end
end
