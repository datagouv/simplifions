class CatalogCardComponent < ApplicationComponent
  def self.pour(record, arrow: false)
    (record.is_a?(Demarche) ? DemarcheCardComponent : SolutionCardComponent).pour(record, arrow:)
  end

  def initialize(card:, arrow: false)
    @card = card
    @arrow = arrow
  end

  def call
    if @card[:href].to_s.start_with?('/cas-d-usages/')
      render DemarcheCardComponent.new(card: @card, arrow: @arrow)
    else
      render SolutionCardComponent.new(card: @card, arrow: @arrow)
    end
  end
end
