class DemarchesController < ApplicationController
  def index
    @filtres = filtres_catalogue
    @catalogue = paginer(Demarche.catalogue(@filtres).includes(:vocabulaires, :types_acteurs), 20)
  end

  def show
    @demarche = Demarche.visibles.find_by!(slug: params.expect(:slug))
  end
end
