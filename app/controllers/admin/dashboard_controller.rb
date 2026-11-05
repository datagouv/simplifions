class Admin::DashboardController < Admin::BaseController
  CATALOGUE = [Demarche, Solution, Organisation, TypeActeur, Vocabulaire].freeze

  def index
    @demarches_en_brouillon = Demarche.en_brouillon.count
    @solutions_en_brouillon = Solution.en_brouillon.count
    @catalogue = CATALOGUE.index_with(&:count)
    @publiees = [Demarche, Solution].index_with { it.visibles.count }
    @dernier_rafraichissement = RafraichirCatalogueJob.dernier_passage
  end
end
