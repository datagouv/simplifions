class Grist::PersistCatalogue < ApplicationOrganizer
  organize Grist::ImportEntites, Grist::ImportRecommandations,
    Grist::ImportIntegrations, Grist::PruneDisparus

  UN_SEUL_IMPORT_A_LA_FOIS = 20_260_806

  around do |organizer|
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.exec_query('SELECT pg_advisory_xact_lock($1)', 'SQL', [UN_SEUL_IMPORT_A_LA_FOIS])
      organizer.call
    end
  end
end
