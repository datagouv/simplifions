class DataserviceCardComponent < ApplicationComponent
  # Mêmes libellés, couleurs et icônes que le site actuel (accessTypeBadge.ts).
  BADGES = {
    'open' => ['%<nature>s %<ouvert>s', 'fr-badge--info', 'fr-icon-arrow-left-right-line'],
    'open_with_account' => ['%<nature>s %<ouvert>s avec compte', 'fr-badge--info', 'fr-icon-user-line'],
    'restricted/yes' => ['%<nature>s %<restreint>s · accessible aux acteurs publics', 'fr-badge--success',
                         'fr-icon-lock-unlock-line'],
    'restricted/under_condition' => ['%<nature>s %<restreint>s · accessible aux acteurs publics sous conditions',
                                     'fr-badge--green-tilleul-verveine', 'fr-icon-lock-line'],
    'restricted' => ['%<nature>s en accès restreint', 'fr-badge--orange-terre-battue', 'fr-icon-lock-line']
  }.freeze
  MOTS = { api: { nature: 'API', ouvert: 'ouverte', restreint: 'restreinte' },
           jeu: { nature: 'Jeu de données', ouvert: 'ouvert', restreint: 'restreint' } }.freeze

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

  # Le statut « ouvert avec compte » n'existe pas pour les jeux de données : pas de badge dans ce cas.
  def badge
    acces = solution.datagouv_acces
    return if acces == 'open_with_account' && jeu_de_donnees?

    format, classe, icone = BADGES["#{acces}/#{solution.datagouv_acces_acteurs_publics}"] || BADGES[acces] || return
    { label: format(format, **MOTS[jeu_de_donnees? ? :jeu : :api]), classe:, icone: }
  end

  def lien_label
    jeu_de_donnees? ? 'Voir le jeu de données sur Data.gouv.fr' : "Voir l'API sur Data.gouv.fr"
  end
end
