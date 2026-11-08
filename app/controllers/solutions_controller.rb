class SolutionsController < ApplicationController
  def index
    @filtres = filtres_catalogue
    @catalogue = paginer(Solution.catalogue(@filtres).includes(:vocabulaires, :types_acteurs, :organisations).with_attached_image, 20)
    @guide = guide_du_catalogue
  end

  def show
    @solution = Solution.visibles.find_by!(slug: params.expect(:slug))
  end
end
