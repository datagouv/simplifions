class Grist::PersistCatalogue < ApplicationOrganizer
  organize Grist::ImportEntites, Grist::ImportIntegrations,
    Grist::ImportRecommandations, Grist::PruneDisparus

  # Un seul import à la fois : au déploiement, chaque hôte lance le sien sur la même base.
  LOCK_KEY = 20_260_806

  around do |organizer|
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.exec_query('SELECT pg_advisory_xact_lock($1)', 'SQL', [LOCK_KEY])
      organizer.call
    end
  end
end
