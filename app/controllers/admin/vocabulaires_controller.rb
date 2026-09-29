class Admin::VocabulairesController < Admin::BaseController
  def index
    @vocabulaires = Vocabulaire.order(:id)
  end
end
