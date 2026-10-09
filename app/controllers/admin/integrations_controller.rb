class Admin::IntegrationsController < Admin::BaseController
  before_action :set_integration, only: %i[edit update destroy]

  def index
    @integrations = paginer(Integration.rechercher(params[:q], :integratrice_nom_sans_accent_cont, :integree_nom_sans_accent_cont).includes(:integratrice, :integree).order(:id))
  end

  def new
    @integration = Integration.new(integratrice_id: params[:integratrice_id])
  end

  def edit; end

  def create
    @integration = Integration.new(integration_params)
    enregistrer_puis_repondre(:new, @integration.save)
  end

  def update
    enregistrer_puis_repondre(:edit, @integration.update(integration_params))
  end

  def destroy
    @integration.destroy!
    return render :destroy, formats: :turbo_stream if params[:ligne]

    redirect_to admin_integrations_path, notice: t('admin.supprime', nom: nom_de(@integration)), status: :see_other
  end

  private

  def enregistrer_puis_repondre(page, enregistree)
    if params[:ligne]
      @cote = params[:cote] == 'integratrice' ? :integratrice : :integree
      render :ligne, formats: :turbo_stream, status: enregistree ? :ok : :unprocessable_content
    elsif enregistree
      redirige_vers_la_fiche(@integration)
    else
      render page, status: :unprocessable_content
    end
  end

  def set_integration
    @integration = Integration.find(params.expect(:id))
  end

  def integration_params
    params.expect(integration: [:integratrice_id, :integree_id, :type_integration, :statut, { demarche_ids: [] }])
  end
end
