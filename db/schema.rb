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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_165000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
  end

  create_table "demarches_types_acteurs", id: false, force: :cascade do |t|
    t.bigint "demarche_id", null: false
    t.bigint "type_acteur_id", null: false
    t.index ["demarche_id", "type_acteur_id"], name: "idx_on_demarche_id_type_acteur_id_e6293e9502", unique: true
  end

  create_table "demarches_vocabulaires", id: false, force: :cascade do |t|
    t.bigint "demarche_id", null: false
    t.bigint "vocabulaire_id", null: false
    t.index ["demarche_id", "vocabulaire_id"], name: "index_demarches_vocabulaires_on_demarche_id_and_vocabulaire_id", unique: true
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
    t.index ["demarche_id"], name: "index_recommandations_on_demarche_id"
    t.index ["grist_id"], name: "index_recommandations_on_grist_id", unique: true
    t.index ["solution_id"], name: "index_recommandations_on_solution_id"
  end

  create_table "solutions", force: :cascade do |t|
    t.string "categorie"
    t.datetime "created_at", null: false
    t.datetime "cree_le"
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
  end

  create_table "solutions_vocabulaires", id: false, force: :cascade do |t|
    t.bigint "solution_id", null: false
    t.bigint "vocabulaire_id", null: false
    t.index ["solution_id", "vocabulaire_id"], name: "index_solutions_vocabulaires_on_solution_id_and_vocabulaire_id", unique: true
  end

  create_table "types_acteurs", force: :cascade do |t|
    t.text "codes_juridiques"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "grist_id"
    t.string "nom", null: false
    t.string "slug"
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
end
