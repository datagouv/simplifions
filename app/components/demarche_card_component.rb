class DemarcheCardComponent < ApplicationComponent
  def self.pour(demarche, arrow: false)
    new(arrow:, card: { title: "#{demarche.icone} #{demarche.nom}".strip, href: "/demarches/#{demarche.slug}" })
  end

  def initialize(card:, arrow: false)
    @card = card
    @arrow = arrow
  end
end
