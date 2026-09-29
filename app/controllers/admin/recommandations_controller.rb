class Admin::RecommandationsController < Admin::BaseController
  def index
    @recommandations = Recommandation.includes(:demarche, :solution).order(:id)
  end
end
