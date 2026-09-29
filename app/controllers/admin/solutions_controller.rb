class Admin::SolutionsController < Admin::BaseController
  def index
    @solutions = Solution.order(:id)
  end
end
