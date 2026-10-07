class Grist::Import < ApplicationOrganizer
  organize Grist::FetchTables, Grist::PersistCatalogue, Grist::AttachImages

  around { |import| PaperTrail.request(whodunnit: 'Import Grist') { import.call } }

  before do
    context.report = { quarantine: [], notes: [] }
    context.index = {}
    context.seen = Hash.new { |modeles, modele| modeles[modele] = [] }
  end
end
