module FiltresHelper
  def valeur_de_filtre(options, valeurs) = options.map(&:last).intersection(valeurs).join(',')

  def tags_du_catalogue(filtres, klass, nom, label, options)
    valeurs = filtres[nom].to_s.split(',')
    options.map do |libelle, slug|
      choisi = valeurs.include?(slug)
      { libelle:, nom:, choisi:,
        valeur: valeur_de_filtre(options, choisi ? valeurs - [slug] : valeurs + [slug]),
        compte: klass.catalogue(filtres.to_h.merge(nom => slug)).count,
        data: { matomo_action: 'Choisir un filtre', matomo_fermeture: 'Retirer un filtre', matomo_nom: "#{label} : #{libelle}" } }
    end
  end

  def tags_des_articles(choisis, categorie, mots_cles)
    mots_cles.map do |mot_cle|
      choisi = choisis.include?(mot_cle)
      { libelle: mot_cle, nom: 'keywords', choisi:,
        valeur: (choisi ? choisis - [mot_cle] : choisis + [mot_cle]).join(','),
        compte: Article.count_for(mot_cle, choisis, categorie),
        data: { matomo_action: 'Filtrer par mot-clé', matomo_fermeture: 'Retirer un mot-clé', matomo_nom: mot_cle } }
    end
  end
end
