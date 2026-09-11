class DataserviceCardComponent < ApplicationComponent
  # Mêmes libellés, couleurs et icônes que le site actuel (accessTypeBadge.ts) : [nature, accès, accès des
  # acteurs publics] → badge ; « ouvert avec compte » n'existe pas pour les jeux de données.
  BADGES = {
    %w[api open] => ['API ouverte', 'fr-badge--info', 'fr-icon-arrow-left-right-line'],
    %w[jeu open] => ['Jeu de données ouvert', 'fr-badge--info', 'fr-icon-arrow-left-right-line'],
    %w[api open_with_account] => ['API ouverte avec compte', 'fr-badge--info', 'fr-icon-user-line'],
    %w[api restricted yes] => ['API restreinte · accessible aux acteurs publics', 'fr-badge--success',
                               'fr-icon-lock-unlock-line'],
    %w[jeu restricted yes] => ['Jeu de données restreint · accessible aux acteurs publics', 'fr-badge--success',
                               'fr-icon-lock-unlock-line'],
    %w[api restricted under_condition] => ['API restreinte · accessible aux acteurs publics sous conditions',
                                           'fr-badge--green-tilleul-verveine', 'fr-icon-lock-line'],
    %w[jeu restricted under_condition] => ['Jeu de données restreint · accessible aux acteurs publics sous conditions',
                                           'fr-badge--green-tilleul-verveine', 'fr-icon-lock-line'],
    %w[api restricted] => ['API en accès restreint', 'fr-badge--orange-terre-battue', 'fr-icon-lock-line'],
    %w[jeu restricted] => ['Jeu de données en accès restreint', 'fr-badge--orange-terre-battue', 'fr-icon-lock-line']
  }.freeze

  def initialize(solution, heading: 'h3')
    @solution = solution
    @heading = heading
  end

  private

  attr_reader :solution

  delegate :datagouv_logo, :lien_datagouv, to: :solution

  def jeu_de_donnees? = solution.categorie_base_de_donnees?
  def titre = solution.datagouv_titre.presence || solution.nom

  def producteur
    solution.datagouv_organisation.presence ||
      solution.organisations.first&.then { |orga| orga.nom_long.presence || orga.nom }
  end

  def badge
    nature = jeu_de_donnees? ? 'jeu' : 'api'
    acces = solution.datagouv_acces
    label, classe, icone = BADGES[[nature, acces, solution.datagouv_acces_acteurs_publics]] || BADGES[[nature, acces]] || return
    { label:, classe:, icone: }
  end

  def service_public? = solution.datagouv_organisation_badges.include?('public-service')
  def certifiee? = solution.datagouv_organisation_badges.include?('certified')

  def lien_label
    jeu_de_donnees? ? 'Voir le jeu de données sur Data.gouv.fr' : "Voir l'API sur Data.gouv.fr"
  end
end
