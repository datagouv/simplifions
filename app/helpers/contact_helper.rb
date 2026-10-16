module ContactHelper
  def objet_du_message(objet, fiche)
    [objet, fiche&.first].compact.join(' : ')
  end

  def libelle_solution(solution)
    [solution.nom, solution.organisations.first&.nom].compact.join(' – ')
  end

  def corps_du_message(informations, fiche)
    lignes = fiche ? ["Fiche concernée : #{fiche.join(' – ')}", ''] : []
    lignes += informations.flat_map do |libelle, options|
      next ["#{libelle} :", ''] if options.blank?

      ["#{libelle} (gardez les mentions utiles) :", *options.map { |option| "- #{option}" }, '']
    end
    ['Bonjour,', '', *lignes].join("\n")
  end
end
