module ContactHelper
  def objet_du_message(objet)
    "[Simplifions.data] #{objet}"
  end

  def corps_du_message(informations)
    lignes = informations.flat_map do |libelle, options|
      next ["#{libelle} :", ''] if options.blank?

      ["#{libelle} (gardez les mentions utiles) :", *options.map { |option| "- #{option}" }, '']
    end
    ['Bonjour,', '', *lignes, '', 'Cordialement,'].join("\n")
  end
end
