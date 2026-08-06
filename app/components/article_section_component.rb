class ArticleSectionComponent < ApplicationComponent
  def initialize(id:, label:, heading: nil)
    @id = id
    @heading = heading || label
  end
end
