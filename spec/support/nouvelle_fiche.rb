module NouvelleFiche
  def nouvelle_fiche(chemin) = chemin == 'solutions' ? '/admin/solutions/new?categorie=logiciel_metier_cle_en_main' : "/admin/#{chemin}/new"
end

RSpec.configure { it.include NouvelleFiche, type: :request }
