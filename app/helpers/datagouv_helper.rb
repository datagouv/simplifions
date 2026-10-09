module DatagouvHelper
  # Mêmes libellés, couleurs et icônes que le site actuel (accessTypeBadge.ts) : [nature, accès, accès des
  # acteurs publics] → badge ; « ouvert avec compte » n'existe pas pour les jeux de données.
  BADGES_ACCES = {
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

  def badge_acces_datagouv(solution)
    cle = [solution.categorie_base_de_donnees? ? 'jeu' : 'api', solution.datagouv_acces]
    label, classe, icone = BADGES_ACCES[[*cle, solution.datagouv_acces_acteurs_publics]] || BADGES_ACCES[cle] || return
    tag.p(class: "fr-badge fr-badge--sm fr-badge--no-icon #{classe}") do
      safe_join([tag.span(class: "#{icone} fr-icon--sm fr-mr-1v", aria: { hidden: true }), label])
    end
  end
end
