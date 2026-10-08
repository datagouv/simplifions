class Admin::HistoriquesController < Admin::BaseController
  MODELES = [Demarche, Solution, Recommandation, Integration, Organisation, TypeActeur, Vocabulaire].index_by { it.model_name.route_key }.freeze

  before_action :en_base

  def show; end

  private

  def modele = MODELES[params[:type]] || raise(ActiveRecord::RecordNotFound)

  def fil_d_ariane
    [['Administration', admin_root_path], [modele.model_name.human(count: 2), polymorphic_path([:admin, modele])],
     [nom_en_base, polymorphic_path(helpers.fiche_admin(en_base))], ['Historique', nil]]
  end
end
