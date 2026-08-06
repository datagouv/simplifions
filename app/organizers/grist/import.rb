class Grist::Import < ApplicationOrganizer
  organize Grist::FetchTables, Grist::PersistCatalogue, Grist::AttachImages

  before do
    context.report = { quarantine: [], notes: [] }
    context.index = {}
  end
end
