class Admin::TypesActeursController < Admin::BaseController
  def index
    @types_acteurs = TypeActeur.order(:id)
  end
end
