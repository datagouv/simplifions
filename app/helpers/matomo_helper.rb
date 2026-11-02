module MatomoHelper
  ACCES_MATOMO = {
    %w[open] => 'ouvert',
    %w[open_with_account] => 'ouvert avec compte',
    %w[restricted yes] => 'restreint public',
    %w[restricted under_condition] => 'restreint public sous conditions',
    %w[restricted] => 'restreint'
  }.freeze

  def matomo_zone(zone, contexte = nil) = { matomo_zone: zone, matomo_contexte: contexte }.compact

  def matomo_evenement(action, nom, solution)
    precisions = [matomo_type(solution), matomo_acces(solution), matomo_statut(solution)].compact
    { matomo_action: action, matomo_nom: [nom, ("[#{precisions.join(', ')}]" if precisions.any?)].compact.join(' ') }
  end

  def matomo_sortie_datagouv(nom, solution) = matomo_evenement('Ouvrir la fiche data.gouv', nom, solution)

  def matomo_fiche_solution(solution) = matomo_evenement('Ouvrir la fiche solution', solution.nom, solution)

  private

  def matomo_type(solution)
    return 'Jeu de données' if solution.categorie_base_de_donnees?
    return 'API' if solution.categorie_api? || solution.types_solution.include?('API')

    Solution.human_attribute_name("categorie.#{solution.categorie}") if solution.categorie
  end

  def matomo_acces(solution)
    ACCES_MATOMO[[solution.datagouv_acces, solution.datagouv_acces_acteurs_publics]] ||
      ACCES_MATOMO[[solution.datagouv_acces]]
  end

  def matomo_statut(solution)
    return unless solution.organisations.any?

    solution.privee? ? 'privée' : 'publique'
  end
end
