class Grist::PruneDisparus < Grist::ImportStep
  MODELES = [Organisation, TypeActeur, Vocabulaire, Demarche, Solution,
             Integration, Recommandation, Utilite].freeze

  def call
    MODELES.each { |model| prune(model) }
  end

  private

  def prune(model)
    vus = context.seen[model.name]
    context.fail!(error: "#{model.name} : aucune ligne importée ce run, purge refusée") if vus.empty?

    disparus = model.where.not(id: vus).destroy_all
    return if disparus.empty?

    note("#{model.name} : #{disparus.size} ligne(s) absente(s) du run (disparues ou en quarantaine) supprimée(s)")
  end
end
