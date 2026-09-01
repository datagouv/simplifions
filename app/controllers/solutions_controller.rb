class SolutionsController < ApplicationController
  def index
    @catalogue = Solution.catalogue(params).includes(:vocabulaires, :types_acteurs, :organisations).with_attached_image
  end

  def show
    @solution = Solution.visibles.find_by!(slug: params.expect(:slug))
  end
end
