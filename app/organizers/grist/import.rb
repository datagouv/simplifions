class Grist::Import < ApplicationOrganizer
  organize Grist::FetchTables, Grist::PersistCatalogue

  before do
    context.report = { quarantine: [], notes: [] }
    context.index = {}
    context.seen = Hash.new { |modeles, modele| modeles[modele] = [] }
  end
end
