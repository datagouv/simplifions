module AdminHelper
  def rubrique_admin_ouverte?(modele) = (params[:type] || controller_name) == modele.model_name.route_key

  def lien_rubrique_admin(modele)
    liste = polymorphic_path([:admin, modele])
    link_to modele.model_name.human(count: 2), liste, class: 'fr-nav__link',
      aria: { current: ((current_page?(liste) ? 'page' : 'true') if rubrique_admin_ouverte?(modele)) }
  end
end
