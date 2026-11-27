module SolutionsHelper
  INTRO_USAGERS = { integrees: 'Solution intégrant des données des', fournies: 'Solution fournissant des données des' }.freeze

  def public_vise_de_solution(solution)
    { intro_usagers: INTRO_USAGERS.fetch(solution.donnees_affichees, 'Solution pour les'),
      intro_acteurs: { tous: 'Solution à destination de', autres: 'Solution à destination des' } }
  end
end
