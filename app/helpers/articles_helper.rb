module ArticlesHelper
  def solution_card(slug, **retouches)
    solution = Solution.visibles.find_by(slug:)
    SolutionCardComponent.pour(solution, description: nil, acteurs: nil, **retouches) if solution
  end

  def demarche_card(slug, **retouches)
    demarche = Demarche.visibles.find_by(slug:)
    DemarcheCardComponent.pour(demarche, description: nil, **retouches) if demarche
  end
end
