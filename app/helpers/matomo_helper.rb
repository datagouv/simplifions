module MatomoHelper
  ACCES_MATOMO = {
    %w[open] => 'ouvert',
    %w[open_with_account] => 'ouvert avec compte',
    %w[restricted yes] => 'restreint public',
    %w[restricted under_condition] => 'restreint public sous conditions',
    %w[restricted] => 'restreint'
  }.freeze
  ACCES_OPEN_DATA = %w[open open_with_account].freeze

  def matomo_evenement(action, nom, solution, origine = nil)
    precisions = [matomo_type(solution), matomo_acces(solution), origine].compact
    { matomo_action: action, matomo_nom: "#{nom} [#{precisions.join(', ')}]" }
  end

  def matomo_sortie_datagouv(nom, solution, page, lien)
    ouverte = ACCES_OPEN_DATA.include?(solution.datagouv_acces)
    action = ouverte ? 'Sortie fiche data.gouv accès ouvert' : 'Sortie fiche data.gouv accès restreint'
    matomo_evenement(action, nom, solution, "#{page}, #{lien}")
  end

  def matomo_fiche_solution(solution, origine)
    return {} unless solution.types_solution.include?('API')

    matomo_evenement('Ouverture fiche solution API-jdd', solution.nom, solution, origine)
  end

  private

  def matomo_type(solution) = solution.categorie_base_de_donnees? ? 'Jeu de données' : 'API'

  def matomo_acces(solution)
    ACCES_MATOMO[[solution.datagouv_acces, solution.datagouv_acces_acteurs_publics]] ||
      ACCES_MATOMO[[solution.datagouv_acces]]
  end
end
