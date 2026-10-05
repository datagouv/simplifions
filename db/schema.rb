# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_05_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_db_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.binary "data", null: false
    t.string "ref", null: false
    t.index ["ref"], name: "index_active_storage_db_files_on_ref", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.datetime "remember_created_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "demarches", force: :cascade do |t|
    t.text "cadre_juridique"
    t.text "contexte"
    t.datetime "created_at", null: false
    t.datetime "cree_le"
    t.text "description_courte"
    t.string "grist_id"
    t.string "icone"
    t.datetime "modifie_le"
    t.string "mots_clefs", default: [], null: false, array: true
    t.string "nom", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.boolean "visible", default: false, null: false
    t.index ["grist_id"], name: "index_demarches_on_grist_id", unique: true
    t.index ["slug"], name: "index_demarches_on_slug", unique: true
  end

  create_table "demarches_integrations", id: false, force: :cascade do |t|
    t.bigint "demarche_id", null: false
    t.bigint "integration_id", null: false
    t.index ["demarche_id", "integration_id"], name: "index_demarches_integrations_on_demarche_id_and_integration_id", unique: true
    t.index ["integration_id"], name: "index_demarches_integrations_on_integration_id"
  end

  create_table "demarches_types_acteurs", id: false, force: :cascade do |t|
    t.bigint "demarche_id", null: false
    t.bigint "type_acteur_id", null: false
    t.index ["demarche_id", "type_acteur_id"], name: "idx_on_demarche_id_type_acteur_id_e6293e9502", unique: true
    t.index ["type_acteur_id"], name: "index_demarches_types_acteurs_on_type_acteur_id"
  end

  create_table "demarches_vocabulaires", id: false, force: :cascade do |t|
    t.bigint "demarche_id", null: false
    t.bigint "vocabulaire_id", null: false
    t.index ["demarche_id", "vocabulaire_id"], name: "index_demarches_vocabulaires_on_demarche_id_and_vocabulaire_id", unique: true
    t.index ["vocabulaire_id"], name: "index_demarches_vocabulaires_on_vocabulaire_id"
  end

  create_table "integrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "grist_id"
    t.bigint "integratrice_id", null: false
    t.bigint "integree_id", null: false
    t.string "statut"
    t.string "type_integration", null: false
    t.datetime "updated_at", null: false
    t.index ["grist_id"], name: "index_integrations_on_grist_id", unique: true
    t.index ["integratrice_id"], name: "index_integrations_on_integratrice_id"
    t.index ["integree_id"], name: "index_integrations_on_integree_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "grist_id"
    t.string "nom", null: false
    t.string "nom_long"
    t.string "public_ou_prive"
    t.string "site_internet"
    t.string "type_organisation_privee"
    t.datetime "updated_at", null: false
    t.index ["grist_id"], name: "index_organisations_on_grist_id", unique: true
  end

  create_table "organisations_solutions", id: false, force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "solution_id", null: false
    t.index ["organisation_id", "solution_id"], name: "idx_on_organisation_id_solution_id_c637cc21ae", unique: true
    t.index ["solution_id"], name: "index_organisations_solutions_on_solution_id"
  end

  create_table "recommandations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "demarche_id", null: false
    t.text "description"
    t.text "donnees_utiles"
    t.string "grist_id"
    t.datetime "modifie_le"
    t.integer "niveau"
    t.integer "ordre"
    t.text "parametres_a_saisir"
    t.bigint "solution_id", null: false
    t.datetime "updated_at", null: false
    t.string "url_demande_acces"
    t.boolean "visible", default: false, null: false
    t.index ["demarche_id", "solution_id"], name: "index_recommandations_on_demarche_id_and_solution_id", unique: true
    t.index ["grist_id"], name: "index_recommandations_on_grist_id", unique: true
    t.index ["solution_id"], name: "index_recommandations_on_solution_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "solutions", force: :cascade do |t|
    t.string "categorie"
    t.datetime "created_at", null: false
    t.datetime "cree_le"
    t.string "datagouv_acces"
    t.string "datagouv_acces_acteurs_publics"
    t.string "datagouv_logo"
    t.string "datagouv_organisation"
    t.string "datagouv_organisation_badges", default: [], null: false, array: true
    t.string "datagouv_titre"
    t.text "description_courte"
    t.boolean "france_connectee", default: false, null: false
    t.string "grist_id"
    t.text "legende_image"
    t.datetime "modifie_le"
    t.text "ne_permet_pas"
    t.string "nom", null: false
    t.text "permet"
    t.string "site_internet"
    t.string "slug"
    t.string "types_solution", default: [], null: false, array: true
    t.string "uid_datagouv"
    t.datetime "updated_at", null: false
    t.string "url_demande_acces"
    t.boolean "visible", default: false, null: false
    t.index ["grist_id"], name: "index_solutions_on_grist_id", unique: true
    t.index ["slug"], name: "index_solutions_on_slug", unique: true
  end

  create_table "solutions_types_acteurs", id: false, force: :cascade do |t|
    t.bigint "solution_id", null: false
    t.bigint "type_acteur_id", null: false
    t.index ["solution_id", "type_acteur_id"], name: "idx_on_solution_id_type_acteur_id_b3c16472c6", unique: true
    t.index ["type_acteur_id"], name: "index_solutions_types_acteurs_on_type_acteur_id"
  end

  create_table "solutions_vocabulaires", id: false, force: :cascade do |t|
    t.bigint "solution_id", null: false
    t.bigint "vocabulaire_id", null: false
    t.index ["solution_id", "vocabulaire_id"], name: "index_solutions_vocabulaires_on_solution_id_and_vocabulaire_id", unique: true
    t.index ["vocabulaire_id"], name: "index_solutions_vocabulaires_on_vocabulaire_id"
  end

  create_table "types_acteurs", force: :cascade do |t|
    t.text "codes_juridiques"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "grist_id"
    t.string "nom", null: false
    t.string "slugs", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.index ["grist_id"], name: "index_types_acteurs_on_grist_id", unique: true
  end

  create_table "vocabulaires", force: :cascade do |t|
    t.string "categorie", null: false
    t.datetime "created_at", null: false
    t.string "grist_id"
    t.string "nom", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["grist_id"], name: "index_vocabulaires_on_grist_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "integrations", "solutions", column: "integratrice_id"
  add_foreign_key "integrations", "solutions", column: "integree_id"
  add_foreign_key "recommandations", "demarches"
  add_foreign_key "recommandations", "solutions"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
