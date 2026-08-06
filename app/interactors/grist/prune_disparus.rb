class Grist::PruneDisparus < Grist::ImportStep
  MODELES = [Organisation, TypeActeur, Vocabulaire, Demarche, Solution,
             Integration, Recommandation, Utilite].freeze

  def call
    MODELES.each do |model|
      disparus = model.where.not(id: context.seen[model.name]).destroy_all
      note("#{model.name} : #{disparus.size} ligne(s) disparue(s) de Grist supprimée(s)") if disparus.any?
    end
  end
end
