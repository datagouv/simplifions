class SolutionCardComponent < ApplicationComponent
  def self.pour(solution, arrow: false)
    new(arrow:, card: {
      title: solution.nom, href: "/solutions/#{solution.slug}", badge: badge_operateur(solution),
      description: solution.description_courte.to_s.lines.first&.strip,
      usagers: solution.usagers, acteurs: solution.acteurs,
      image: (solution.image if solution.image.attached?)
    })
  end

  def initialize(card:, arrow: false)
    @card = card
    @arrow = arrow
  end

  def self.badge_operateur(solution)
    operateur = solution.organisations.first
    "#{solution.privee? ? 'Solution privée' : 'Solution publique'} | #{operateur.nom}" if operateur
  end

  private

  def badge
    return if @card[:badge].blank?

    text, operator = @card[:badge].split(' | ', 2)
    tag.p(class: badge_classes) do
      tag.span(class: 'font-weight-normal') do
        operator ? safe_join([text, ' | ', tag.b(operator)]) : text
      end
    end
  end

  def badge_classes
    color = @card[:badge].start_with?('Solution privée') ? 'fr-badge--green-tilleul-verveine' : 'fr-badge--blue-ecume'
    "fr-badge fr-badge--sm fr-badge--no-icon #{color}"
  end
end
