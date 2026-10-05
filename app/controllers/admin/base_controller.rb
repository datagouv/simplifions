class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!

  private

  def redirige_vers_la_fiche(ligne)
    redirect_to [:edit, :admin, ligne], notice: t('admin.enregistre', nom: nom_de(ligne)), status: :see_other
  end

  def nom_de(ligne) = ligne.respond_to?(:nom) ? ligne.nom : ligne.libelle
end
