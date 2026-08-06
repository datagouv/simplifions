class ArticleLayoutComponent < ApplicationComponent
  def initialize(article:, mentions: [])
    @article = article
    @mentions = mentions
  end
end
