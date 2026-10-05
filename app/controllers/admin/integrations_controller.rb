class Admin::IntegrationsController < Admin::BaseController
  before_action :set_integration, only: %i[edit update destroy]

  def index
    @integrations = paginer(Integration.nom_contient(params[:q]).includes(:integratrice, :integree).order(:id))
  end

  def new
    @integration = Integration.new
  end

  def edit; end

  def create
    @integration = Integration.new(integration_params)
    if @integration.save
      redirige_vers_la_fiche(@integration)
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @integration.update(integration_params)
      redirige_vers_la_fiche(@integration)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @integration.destroy!
    redirect_to admin_integrations_path, notice: t('admin.supprime', nom: nom_de(@integration)), status: :see_other
  end

  private

  def set_integration
    @integration = Integration.find(params.expect(:id))
  end

  def integration_params
    params.expect(integration: [:integratrice_id, :integree_id, :type_integration, :statut, { demarche_ids: [] }])
  end
end
