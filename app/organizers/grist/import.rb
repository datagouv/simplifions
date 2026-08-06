class Grist::Import < ApplicationOrganizer
  organize Grist::FetchTables, Grist::ImportEntites, Grist::ImportIntegrations,
    Grist::ImportRecommandations, Grist::ImportUtilites, Grist::AttachImages

  around do |organizer|
    ActiveRecord::Base.transaction { organizer.call }
  end

  before do
    context.report = { quarantine: [], notes: [] }
    context.index = {}
  end
end
