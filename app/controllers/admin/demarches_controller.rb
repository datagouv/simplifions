class Admin::DemarchesController < Admin::BaseController
  before_action :set_demarche, only: %i[edit update destroy]

  def index
    @demarches = paginer(Demarche.ransack(recherche: params[:q].to_s).result.order(:id))
  end

  def new
    @demarche = Demarche.new
  end

  def edit; end

  def create
    @demarche = Demarche.new(demarche_params.merge(%i[cree_le modifie_le].index_with(Time.current)))
    if @demarche.save
      redirige_vers_la_fiche(@demarche)
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @demarche.update(demarche_params.merge(modifie_le: Time.current))
      redirige_vers_la_fiche(@demarche)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @demarche.destroy!
    redirect_to admin_demarches_path, notice: t('admin.supprime', nom: nom_de(@demarche)), status: :see_other
  end

  private

  def set_demarche
    @demarche = Demarche.find(params.expect(:id))
  end

  def demarche_params
    params.expect(demarche: [:nom, :icone, :slug, :mots_clefs, :description_courte, :contexte, :cadre_juridique, :visible, { vocabulaire_ids: [], type_acteur_ids: [], integration_ids: [] }])
  end
end
