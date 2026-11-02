class SolutionCardComponent < ApplicationComponent
  def self.pour(solution, arrow: false, **retouches)
    new(arrow:, card: {
      title: solution.nom, href: "/solutions/#{solution.slug}", solution:,
      description: solution.chapo,
      usagers: solution.usagers, acteurs: solution.acteurs,
      image: (solution.image if solution.image.attached?)
    }.merge(retouches))
  end

  def initialize(card:, arrow: false)
    @card = card
    @arrow = arrow
  end
end
