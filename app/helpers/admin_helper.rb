module AdminHelper
  BLOCS_DE_LA_DEMARCHE = {
    'En-tête modifié' => ['titre-de-la-demarche', %w[icone nom description_courte publics]],
    'Adresse de la page modifiée : l’ancienne adresse ne mènera plus à la démarche' => ['titre-de-la-demarche', %w[slug]],
    'Contexte modifié' => ['bloc-contexte', %w[contexte]],
    'Cadre juridique modifié' => ['bloc-cadre-juridique', %w[cadre_juridique]],
    'Intégrations modifiées' => ['bloc-integrations', %w[integration_ids]],
    'Title SEO modifié' => ['bloc-titre-seo', %w[titre_seo]],
    'Mots-clés modifiés' => ['bloc-mots-clefs', %w[mots_clefs]],
    'Fournisseurs de services modifiés' => ['bloc-fournisseurs', %w[type_acteur_ids]],
    'Vocabulaires modifiés' => ['bloc-vocabulaires', %w[vocabulaires]]
  }.freeze

  def rubrique_admin_ouverte?(modele) = (params[:type] || controller_name) == modele.model_name.route_key

  def lien_rubrique_admin(modele)
    liste = polymorphic_path([:admin, modele])
    link_to modele.model_name.human(count: 2), liste, class: 'fr-nav__link',
      aria: { current: ((current_page?(liste) ? 'page' : 'true') if rubrique_admin_ouverte?(modele)) }
  end

  def changements_a_publier(demarche)
    return [] unless demarche.visible? && demarche.brouillon?

    champs = champs_a_publier(demarche)
    BLOCS_DE_LA_DEMARCHE.filter_map { |libelle, (ancre, champs_du_bloc)| [libelle, ancre] if champs.intersect?(champs_du_bloc) }
  end

  private

  def champs_a_publier(demarche)
    champs = demarche.champs_du_brouillon
    return champs unless champs.delete('vocabulaire_ids')

    en_brouillon = demarche.brouillon['vocabulaire_ids'].compact_blank.map(&:to_i)
    champs + Vocabulaire.where(id: (demarche.vocabulaire_ids.to_set ^ en_brouillon).to_a).map { it.categorie_usager? ? 'publics' : 'vocabulaires' }
  end
end
