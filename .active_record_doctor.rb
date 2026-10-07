JOIN_TABLES = %w[
  demarches_integrations demarches_types_acteurs demarches_vocabulaires
  organisations_solutions solutions_types_acteurs solutions_vocabulaires
].freeze

ActiveRecordDoctor.configure do
  global :ignore_tables, [
    "ar_internal_metadata",
    "schema_migrations",
    # tables d'Active Storage et d'active_storage_db : leur schéma n'est pas le nôtre
    /\Aactive_storage_/,
    /\Asolid_queue_/,
    "versions"
  ]

  global :ignore_models, [
    # modèles des gems, chargés même quand leur table n'existe pas ici
    /\AActiveStorage::/,
    /\AActiveStorageDB::/,
    /\AActionMailbox::/,
    /\AActionText::/,
    "SolidCache::Entry",
    "PaperTrail::Version",
    /\ASolidQueue::/
  ]

  # tables has_and_belongs_to_many : id: false et sans horodatage, voulu
  detector :table_without_primary_key, ignore_tables: JOIN_TABLES
  detector :table_without_timestamps, ignore_tables: JOIN_TABLES

  detector :missing_presence_validation, ignore_attributes: [
    # Devise valide le mot de passe en clair
    "Admin.encrypted_password",
    # tableaux default: [] : vide est une valeur valide, presence la refuserait
    "Demarche.mots_clefs", "Solution.datagouv_organisation_badges", "Solution.types_solution", "TypeActeur.slugs",
    # booléens null: false : presence refuserait false
    "Demarche.visible", "Recommandation.visible", "Solution.visible", "Solution.france_connectee"
  ]

  detector :incorrect_dependent_option, ignore_associations: [
    # delete_all sauterait le nettoyage habtm de demarches_integrations
    "Solution.integrations_comme_integratrice", "Solution.integrations_comme_integree"
  ]
end
