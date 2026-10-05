class Admin::RecommandationsController < Admin::BaseController
  before_action :set_recommandation, only: %i[edit update destroy]

  def index
    @recommandations = Recommandation.nom_contient(params[:q]).includes(:demarche, :solution).order(:id)
  end

  def new
    @recommandation = Recommandation.new
  end

  def edit; end

  def create
    @recommandation = Recommandation.new(recommandation_params.merge(modifie_le: Time.current))
    if @recommandation.save
      redirige_vers_la_fiche(@recommandation)
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @recommandation.update(recommandation_params.merge(modifie_le: Time.current))
      redirige_vers_la_fiche(@recommandation)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @recommandation.destroy!
    redirect_to admin_recommandations_path, notice: t('admin.supprime', nom: nom_de(@recommandation)), status: :see_other
  end

  private

  def set_recommandation
    @recommandation = Recommandation.find(params.expect(:id))
  end

  def recommandation_params
    params.expect(recommandation: %i[demarche_id solution_id niveau ordre description donnees_utiles parametres_a_saisir url_demande_acces visible])
  end
end
