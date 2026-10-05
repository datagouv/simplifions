class Admin::OrganisationsController < Admin::BaseController
  before_action :set_organisation, only: %i[edit update destroy]

  def index
    @organisations = paginer(Organisation.nom_contient(params[:q]).order(:id))
  end

  def new
    @organisation = Organisation.new
  end

  def edit; end

  def create
    @organisation = Organisation.new(organisation_params)
    if @organisation.save
      redirige_vers_la_fiche(@organisation)
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @organisation.update(organisation_params)
      redirige_vers_la_fiche(@organisation)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @organisation.destroy!
    redirect_to admin_organisations_path, notice: t('admin.supprime', nom: nom_de(@organisation)), status: :see_other
  end

  private

  def set_organisation
    @organisation = Organisation.find(params.expect(:id))
  end

  def organisation_params
    params.expect(organisation: [:nom, :nom_long, :public_ou_prive, :type_organisation_privee, :site_internet, { solution_ids: [] }])
  end
end
