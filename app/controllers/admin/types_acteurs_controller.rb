class Admin::TypesActeursController < Admin::BaseController
  before_action :set_type_acteur, only: %i[edit update destroy]

  def index
    @types_acteurs = TypeActeur.order(:id)
  end

  def new
    @type_acteur = TypeActeur.new
  end

  def edit; end

  def create
    @type_acteur = TypeActeur.new(type_acteur_params)
    if @type_acteur.save
      redirect_to admin_types_acteurs_path, notice: t('admin.enregistre'), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @type_acteur.update(type_acteur_params)
      redirect_to admin_types_acteurs_path, notice: t('admin.enregistre'), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @type_acteur.destroy!
    redirect_to admin_types_acteurs_path, notice: t('admin.supprime', nom: @type_acteur.nom), status: :see_other
  end

  private

  def set_type_acteur
    @type_acteur = TypeActeur.find(params.expect(:id))
  end

  def type_acteur_params
    params.expect(type_acteur: [:nom, :slugs, :description, :codes_juridiques, { demarche_ids: [], solution_ids: [] }])
  end
end
