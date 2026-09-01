class DemarchesController < ApplicationController
  def index
    @filtres = filtres_catalogue
    @catalogue = Demarche.catalogue(@filtres).includes(:vocabulaires, :types_acteurs)
  end

  def show
    @demarche = Demarche.visibles.find_by!(slug: params.expect(:slug))
  end
end
