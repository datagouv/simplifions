class Admin::RafraichissementsController < Admin::BaseController
  def create
    RafraichirCatalogueJob.perform_later
    redirect_to admin_root_path, notice: t('admin.rafraichissement_lance'), status: :see_other
  end
end
