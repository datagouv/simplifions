class Admin::BaseController < ApplicationController
  default_form_builder DsfrFormBuilder
  before_action :authenticate_admin!
  before_action :set_paper_trail_whodunnit
  helper_method :modele, :en_base, :nom_en_base, :fil_d_ariane

  def abandonner_brouillon
    en_base.abandonner_brouillon!
    redirect_to [:edit, :admin, en_base], notice: t('admin.brouillon_abandonne', nom: nom_en_base), status: :see_other
  end

  private

  def paginer(liste) = super(liste, 50)

  def user_for_paper_trail = current_admin.id

  def redirige_vers_la_fiche(ligne)
    cle = ligne.try(:brouillon?) && ligne.visible? ? 'admin.brouillon_enregistre' : 'admin.enregistre'
    redirect_to helpers.fiche_admin(ligne), notice: t(cle, nom: nom_de(ligne)), status: :see_other
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

  def nom_de(ligne)
    return ligne.libelle_admin if ligne.respond_to?(:libelle_admin)

    ligne.respond_to?(:nom) ? ligne.nom : ligne.libelle
  end
end
