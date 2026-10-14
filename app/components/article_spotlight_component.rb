class ArticleSpotlightComponent < ApplicationComponent
  def initialize(cards:)
    @cards = cards.compact
  end

  def render? = @cards.any?
end
