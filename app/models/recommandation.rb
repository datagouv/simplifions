class Recommandation < ApplicationRecord
  belongs_to :demarche
  belongs_to :solution

  scope :visibles, -> { where(visible: true) }

  def solutions_integratrices
    Solution.where(
      id: Integration.en_production.pour_demarche(demarche)
        .where(integree: [solution, *solution.exposees])
        .select(:integratrice_id)
    )
  end

  def moyens_acces
    solutions_integratrices.group_by(&:categorie)
  end
end
