class DemarchesController < ApplicationController
  def index
    @catalogue = Demarche.catalogue(params).includes(:vocabulaires, :types_acteurs)
  end

  def show
    @demarche = Demarche.visibles.find_by!(slug: params.expect(:slug))
  end
end
