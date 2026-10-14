class DemarcheCardComponent < ApplicationComponent
  def self.pour(demarche, arrow: false, **retouches)
    new(arrow:, card: {
      title: demarche.titre, href: "/demarches/#{demarche.slug}",
      description: demarche.chapo,
      usagers: demarche.usagers, acteurs: demarche.acteurs
    }.merge(retouches))
  end

  def initialize(card:, arrow: false)
    @card = card
    @arrow = arrow
  end
end
