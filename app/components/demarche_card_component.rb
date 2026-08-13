class DemarcheCardComponent < ApplicationComponent
  def initialize(card:, arrow: false)
    @card = card
    @arrow = arrow
  end
end
