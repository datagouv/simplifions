class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!
  helper_method :en_base, :nom_en_base, :fil_d_ariane

  private

  def redirige_vers_la_fiche(ligne)
    redirect_to [:edit, :admin, ligne], notice: t('admin.enregistre', nom: nom_de(ligne)), status: :see_other
  end

  def fil_d_ariane
    fil = [['Administration', admin_root_path]]
    return fil if controller_name == 'dashboard'

    fil << [modele.model_name.human(count: 2), url_for(action: :index, only_path: true)]
    fil << [nom_en_base || 'Nouvelle ligne', nil] unless action_name == 'index'
    fil
  end

  def modele = controller_name.classify.constantize

  def en_base = (@en_base ||= modele.find(params.expect(:id)) if params.key?(:id))

  def nom_en_base = en_base && nom_de(en_base)

  def nom_de(ligne) = ligne.respond_to?(:nom) ? ligne.nom : ligne.libelle
end
