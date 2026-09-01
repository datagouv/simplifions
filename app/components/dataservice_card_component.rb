class DataserviceCardComponent < ApplicationComponent
  LOGO_PLACEHOLDER = 'https://placehold.co/40x40'.freeze

  # Le type d'accès et le logo de l'organisation viennent de data.gouv sur le site actuel :
  # placeholders en attendant SIM-28.
  def self.pour(donnee, heading: 'h3')
    new(heading:, api: {
      title: donnee.nom, url: donnee.lien_datagouv, jeu_de_donnees: donnee.categorie_base_de_donnees?,
      org: donnee.organisations.first&.then { |orga| orga.nom_long.presence || orga.nom },
      logo: LOGO_PLACEHOLDER, badge: 'À définir'
    })
  end

  def initialize(api:, heading: 'h3')
    @api = api
    @heading = heading
  end

  private

  def badge
    return { label: 'API restreinte', classe: 'fr-badge--info', icone: 'fr-icon-lock-line' } if @api[:restricted]

    { label: @api[:badge] } if @api[:badge].present?
  end

  def lien_label
    @api[:jeu_de_donnees] ? 'Voir le jeu de données sur Data.gouv.fr' : "Voir l'API sur Data.gouv.fr"
  end
end
