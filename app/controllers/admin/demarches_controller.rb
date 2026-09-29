class Admin::DemarchesController < Admin::BaseController
  def index
    @demarches = Demarche.order(:id)
  end
end
