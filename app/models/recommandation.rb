class Recommandation < ApplicationRecord
  belongs_to :demarche
  belongs_to :solution

  enum :niveau, { niveau_1: 1, niveau_2: 2 }

  validates :solution_id, uniqueness: { scope: :demarche_id }

  scope :visibles, -> { where(visible: true) }

  validate :ne_recommande_pas_de_solution_privee

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

  private

  def ne_recommande_pas_de_solution_privee
    errors.add(:solution, 'une solution privée ne peut pas être mise en avant') if solution&.privee?
  end
end
