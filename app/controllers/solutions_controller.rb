class SolutionsController < ApplicationController
  def show
    @solution = Solution.visibles.find_by!(slug: params.expect(:slug))
  end
end
