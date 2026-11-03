class Admin::IntegrationsController < Admin::BaseController
  before_action :set_integration, only: %i[edit update destroy position]

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

  def position
    @deplacee = deplacer
    respond_to do |format|
      format.turbo_stream { render :position, status: @deplacee ? :ok : :unprocessable_content }
      format.html { redirect_to edit_admin_solution_path(@integration.integratrice, onglet: 'api-fournies'), flash: message_de_deplacement }
    end
  end

  private

  def deplacer = params[:sens] ? @integration.deplacer_d_un_rang(params[:sens]) : @integration.deplacer_a(params.expect(:position).to_i)

  def message_de_deplacement
    return { notice: t('admin.deplacee', nom: nom_de(@integration), position: @integration.ordre) } if @deplacee

    { alert: t('admin.non_deplacee', erreurs: @integration.errors.full_messages.to_sentence) }
  end

  def enregistrer_puis_repondre(page, enregistree)
    if params[:ligne]
      @liste = params.expect(:liste).presence_in(%w[fournies integrees integratrices])&.to_sym || :integrees
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
    params.expect(integration: [:integratrice_id, :integree_id, :type_integration, :statut, :ordre, { demarche_ids: [] }])
  end
end
