module SolutionsHelper
  def public_vise_de_solution(solution)
    { intro_usagers: "Solution #{solution.fournit_sans_integrer? ? 'fournissant' : 'intégrant'} des données des",
      intro_acteurs: { tous: 'Solution à destination de', autres: 'Solution à destination des' } }
  end
end
