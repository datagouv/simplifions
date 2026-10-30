class ErreursController < ApplicationController
  def introuvable
    render status: :not_found, formats: :html
  end
end
