class Grist::PersistCatalogue < ApplicationOrganizer
  organize Grist::ImportEntites, Grist::ImportIntegrations,
    Grist::ImportRecommandations, Grist::ImportUtilites, Grist::PruneDisparus

  around do |organizer|
    ActiveRecord::Base.transaction { organizer.call }
  end
end
