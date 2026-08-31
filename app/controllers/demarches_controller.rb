class DemarchesController < ApplicationController
  def show
    @demarche = Demarche.visibles.find_by!(slug: params.expect(:slug))
  end
end
