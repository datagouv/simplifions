class Admin::DashboardController < Admin::BaseController
  def index
    @demarches_en_brouillon = Demarche.en_brouillon.count
    @solutions_en_brouillon = Solution.en_brouillon.count
    @dernier_rafraichissement = RafraichirCatalogueJob.dernier_passage
  end
end
