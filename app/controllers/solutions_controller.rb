class SolutionsController < ApplicationController
  def index
    @page = [params[:page].to_i, 1].max
    @catalogue = Solution.catalogue(params)
  end

  def show
    @solution = Solution.visibles.find_by!(slug: params.expect(:slug))
  end
end
