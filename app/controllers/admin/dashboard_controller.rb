class Admin::DashboardController < Admin::BaseController
  CATALOGUE = [Demarche, Solution, Organisation, TypeActeur, Vocabulaire].freeze

  def index
    @brouillons = (Demarche.en_brouillon + Solution.en_brouillon).index_with(&:date_du_brouillon).sort_by { |_, date| -date.to_i }
    @catalogue = CATALOGUE.index_with(&:count)
    @publiees = [Demarche, Solution].index_with { it.visibles.count }
    @dernier_rafraichissement = RafraichirCatalogueJob.dernier_passage
  end
end
