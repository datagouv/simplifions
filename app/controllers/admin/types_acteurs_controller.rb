class Admin::TypesActeursController < Admin::BaseController
  before_action :set_type_acteur, only: %i[edit update destroy]

  def index
    @types_acteurs = paginer(TypeActeur.nom_contient(params[:q]).order(:id))
  end

  def new
    @type_acteur = TypeActeur.new
  end

  def edit; end

  def create
    @type_acteur = TypeActeur.new(type_acteur_params)
    if @type_acteur.save
      redirige_vers_la_fiche(@type_acteur)
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @type_acteur.update(type_acteur_params)
      redirige_vers_la_fiche(@type_acteur)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @type_acteur.destroy!
    redirect_to admin_types_acteurs_path, notice: t('admin.supprime', nom: nom_de(@type_acteur)), status: :see_other
  end

  private

  def set_type_acteur
    @type_acteur = TypeActeur.find(params.expect(:id))
  end

  def type_acteur_params
    params.expect(type_acteur: [:nom, :slugs, :description, :codes_juridiques, { demarche_ids: [], solution_ids: [] }])
  end
end
