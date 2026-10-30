module DemarchesHelper
  def titre_demarche(demarche) = avec_icone(demarche.icone, demarche.nom)

  def avec_icone(icone, texte)
    return texte if icone.blank?

    safe_join([tag.span(icone, aria: { hidden: true }), ' ', texte])
  end
end
