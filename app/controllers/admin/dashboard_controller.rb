class Admin::DashboardController < Admin::BaseController
  def index
    @dernier_rafraichissement = RafraichirCatalogueJob.dernier_passage
  end
end
