class DataserviceCardComponent < ApplicationComponent
  def initialize(solution, heading: 'h3')
    @solution = solution
    @heading = heading
  end

  private

  attr_reader :solution

  delegate :datagouv_logo, :lien_datagouv, :producteur, to: :solution

  def jeu_de_donnees? = solution.categorie_base_de_donnees?
  def titre = solution.datagouv_titre.presence || solution.nom
  def badge = helpers.badge_acces_datagouv(solution)

  def service_public? = solution.datagouv_organisation_badges.include?('public-service')
  def certifiee? = solution.datagouv_organisation_badges.include?('certified')

  def lien_label
    jeu_de_donnees? ? 'Voir le jeu de données sur Data.gouv.fr' : "Voir l'API sur Data.gouv.fr"
  end
end
