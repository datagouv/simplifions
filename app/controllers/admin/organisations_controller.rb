class Admin::OrganisationsController < Admin::BaseController
  def index
    @organisations = Organisation.order(:id)
  end
end
