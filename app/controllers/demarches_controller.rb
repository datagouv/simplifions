class DemarchesController < ApplicationController
  def index
    @page = [params[:page].to_i, 1].max
    @catalogue = Demarche.catalogue(params).includes(:vocabulaires, :types_acteurs)
  end

  def show
    @demarche = Demarche.visibles.find_by!(slug: params.expect(:slug))
  end
end
