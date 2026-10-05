class Admin::OrganisationsController < Admin::BaseController
  before_action :set_organisation, only: %i[edit update destroy]

  def index
    @organisations = Organisation.order(:id)
  end

  def new
    @organisation = Organisation.new
  end

  def edit; end

  def create
    @organisation = Organisation.new(organisation_params)
    if @organisation.save
      redirect_to admin_organisations_path, notice: t('admin.enregistre'), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @organisation.update(organisation_params)
      redirect_to admin_organisations_path, notice: t('admin.enregistre'), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @organisation.destroy!
    redirect_to admin_organisations_path, notice: t('admin.supprime'), status: :see_other
  end

  private

  def set_organisation
    @organisation = Organisation.find(params.expect(:id))
  end

  def organisation_params
    params.expect(organisation: [:nom, :nom_long, :public_ou_prive, :type_organisation_privee, :site_internet, { solution_ids: [] }])
  end
end
