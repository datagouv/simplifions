class Admin::VocabulairesController < Admin::BaseController
  before_action :set_vocabulaire, only: %i[edit update destroy]

  def index
    @vocabulaires = Vocabulaire.order(:id)
  end

  def new
    @vocabulaire = Vocabulaire.new
  end

  def edit; end

  def create
    @vocabulaire = Vocabulaire.new(vocabulaire_params)
    if @vocabulaire.save
      redirect_to admin_vocabulaires_path, notice: t('admin.enregistre'), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @vocabulaire.update(vocabulaire_params)
      redirect_to admin_vocabulaires_path, notice: t('admin.enregistre'), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @vocabulaire.destroy!
    redirect_to admin_vocabulaires_path, notice: t('admin.supprime', nom: @vocabulaire.nom), status: :see_other
  end

  private

  def set_vocabulaire
    @vocabulaire = Vocabulaire.find(params.expect(:id))
  end

  def vocabulaire_params
    params.expect(vocabulaire: [:nom, :slug, :categorie, { demarche_ids: [], solution_ids: [] }])
  end
end
