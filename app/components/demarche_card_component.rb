class DemarcheCardComponent < ApplicationComponent
  def self.pour(demarche, arrow: false)
    new(arrow:, card: {
      title: demarche.titre, href: "/demarches/#{demarche.slug}",
      description: demarche.description_courte.to_s.lines.first&.strip,
      usagers: demarche.usagers, acteurs: demarche.acteurs
    })
  end

  def initialize(card:, arrow: false)
    @card = card
    @arrow = arrow
  end
end
