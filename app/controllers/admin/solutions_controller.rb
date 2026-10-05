class Admin::SolutionsController < Admin::BaseController
  before_action :set_solution, only: %i[edit update destroy]

  def index
    @solutions = Solution.order(:id)
  end

  def new
    @solution = Solution.new
  end

  def edit; end

  def create
    @solution = Solution.new(solution_params.merge(%i[cree_le modifie_le].index_with(Time.current)))
    if @solution.save
      redirect_to admin_solutions_path, notice: t('admin.enregistre'), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @solution.update(solution_params.merge(modifie_le: Time.current))
      redirect_to admin_solutions_path, notice: t('admin.enregistre'), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @solution.destroy!
    redirect_to admin_solutions_path, notice: t('admin.supprime'), status: :see_other
  end

  private

  def set_solution
    @solution = Solution.find(params.expect(:id))
  end

  def solution_params
    params.expect(solution: [:nom, :categorie, :slug, :description_courte, :permet, :ne_permet_pas, :image, :legende_image, :site_internet, :url_demande_acces, :uid_datagouv, :types_solution, :france_connectee, :visible, :grist_id, :datagouv_titre, :datagouv_organisation, :datagouv_logo, :datagouv_acces, :datagouv_acces_acteurs_publics, :datagouv_organisation_badges, { organisation_ids: [], vocabulaire_ids: [], type_acteur_ids: [] }])
  end
end
