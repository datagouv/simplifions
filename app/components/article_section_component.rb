class ArticleSectionComponent < ApplicationComponent
  def initialize(id:, label:, heading: nil)
    @id = id
    @label = label
    @heading = heading || label
  end
end
