class Admin::RecommandationsController < Admin::BaseController
  before_action :set_recommandation, only: %i[edit update destroy position]

  def index
    @recommandations = paginer(Recommandation.rechercher(params[:q], :demarche_nom_sans_accent_cont, :solution_nom_sans_accent_cont).includes(:demarche, :solution).order(:id))
  end

  def new
    @recommandation = Recommandation.new(demarche_id: params[:demarche_id])
  end

  def edit
    @recommandation.appliquer_brouillon
  end

  def create
    @recommandation = Recommandation.new
    enregistrer_puis_repondre(:new)
  end

  def update
    enregistrer_puis_repondre(:edit)
  end

  def destroy
    @recommandation.destroy!
    return render :destroy, formats: :turbo_stream if params[:ligne]

    redirect_to admin_recommandations_path, notice: t('admin.supprime', nom: nom_de(@recommandation)), status: :see_other
  end

  def position
    @deplacee = @recommandation.appliquer_brouillon.deplacer_a(params.expect(:position).to_i)
    render :position, formats: :turbo_stream, status: @deplacee ? :ok : :unprocessable_content
  end

  private

  def filtres_de_la_liste(source = params)
    return super unless params[:ligne] && super.empty?

    super(ActionController::Parameters.new(Rack::Utils.parse_query(request.referer.to_s.partition('?').last)))
  rescue Rack::QueryParser::InvalidParameterError
    {}
  end

  def enregistrer_puis_repondre(page)
    enregistree = @recommandation.enregistrer(recommandation_params.merge(modifie_le: Time.current))
    if params[:ligne]
      render :ligne, formats: :turbo_stream, status: enregistree ? :ok : :unprocessable_content
    elsif enregistree
      redirige_vers_la_fiche(@recommandation)
    else
      render page, status: :unprocessable_content
    end
  end

  def set_recommandation
    @recommandation = Recommandation.find(params.expect(:id))
  end

  def recommandation_params
    params.expect(recommandation: %i[demarche_id solution_id niveau ordre description donnees_utiles parametres_a_saisir url_demande_acces visible])
  end
end
