class Admin::SolutionsController < Admin::BaseController
  before_action :set_solution, only: %i[edit update destroy]

  def index
    @solutions = paginer(Solution.ransack(recherche: params[:q].to_s).result.preload(:integratrices, :organisations).order(:id))
  end

  def new
    @solution = Solution.new
  end

  def edit; end

  def create
    @solution = Solution.new(solution_params.merge(%i[cree_le modifie_le].index_with(Time.current)))
    if @solution.save
      redirige_vers_la_fiche(@solution)
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @solution.image = nil if params.dig(:solution, :retirer_image) == '1'
    if @solution.update(solution_params.merge(modifie_le: Time.current))
      redirige_vers_la_fiche(@solution)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @solution.destroy!
    redirect_to admin_solutions_path, notice: t('admin.supprime', nom: nom_de(@solution)), status: :see_other
  end

  private

  def set_solution
    @solution = Solution.find(params.expect(:id))
  end

  def solution_params
    params.expect(solution: [:nom, :categorie, :slug, :description_courte, :permet, :ne_permet_pas, :image, :legende_image, :site_internet, :url_demande_acces, :uid_datagouv, :france_connectee, :visible, { types_solution: [], organisation_ids: [], vocabulaire_ids: [], type_acteur_ids: [] }])
  end
end
