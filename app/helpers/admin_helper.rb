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
  ORDRES = { 'niveau_2' => ['Ordre des solutions recommandées modifié', 'bloc-solutions-recommandees'] }.freeze

  def rubrique_admin_ouverte?(modele) = (params[:type] || controller_name) == modele.model_name.route_key

  def lien_rubrique_admin(modele)
    liste = polymorphic_path([:admin, modele])
    link_to modele.model_name.human(count: 2), liste, class: 'fr-nav__link',
      aria: { current: ((current_page?(liste) ? 'page' : 'true') if rubrique_admin_ouverte?(modele)) }
  end

  def nom_de_la_recommandation(recommandation, nom) = recommandation.retiree? ? tag.s(nom, class: 'fr-text-mention--grey') : nom

  def changements_a_publier(demarche)
    return [] unless demarche.visible?

    champs = demarche.brouillon? ? champs_a_publier(demarche) : []
    blocs = BLOCS_DE_LA_DEMARCHE.filter_map { |libelle, (ancre, champs_du_bloc)| [libelle, ancre] if champs.intersect?(champs_du_bloc) }
    blocs + recommandations_a_publier(demarche.recommandations_en_brouillon.includes(:solution))
  end

  private

  def recommandations_a_publier(recommandations)
    champs = recommandations.index_with(&:champs_du_brouillon)
    nommees = champs.reject { |recommandation, changes| changes == ['ordre'] && ORDRES.key?(recommandation.niveau) }.keys
    nommees.map { recommandation_a_publier(it.appliquer_brouillon) } + ordres_modifies(champs)
  end

  def ordres_modifies(champs)
    deplacees = champs.select { |recommandation, changes| changes.include?('ordre') && !recommandation.ajoutee_au_brouillon? }.keys
    ORDRES.slice(*deplacees.map(&:niveau)).values
  end

  def recommandation_a_publier(recommandation)
    quoi = recommandation.niveau_2? ? 'Solution recommandée' : 'Donnée utile'
    comment = changement_de_la_recommandation(recommandation)
    ancre = recommandation.niveau_2? ? dom_id(recommandation) : 'bloc-donnees-disponibles'
    ["#{quoi} #{comment} : #{recommandation.solution.libelle_admin}", ancre]
  end

  def changement_de_la_recommandation(recommandation)
    return 'retirée' if recommandation.retiree?

    recommandation.ajoutee_au_brouillon? ? 'ajoutée' : 'modifiée'
  end

  def champs_a_publier(demarche)
    champs = demarche.champs_du_brouillon
    return champs unless champs.delete('vocabulaire_ids')

    en_brouillon = demarche.brouillon['vocabulaire_ids'].compact_blank.map(&:to_i)
    champs + Vocabulaire.where(id: (demarche.vocabulaire_ids.to_set ^ en_brouillon).to_a).map { it.categorie_usager? ? 'publics' : 'vocabulaires' }
  end
end
