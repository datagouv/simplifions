class Admin::IntegrationsController < Admin::BaseController
  def index
    @integrations = Integration.includes(:integratrice, :integree).order(:id)
  end
end
