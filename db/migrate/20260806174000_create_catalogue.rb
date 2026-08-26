class CreateCatalogue < ActiveRecord::Migration[8.1]
  def change
    create_table :organisations do |t|
      t.string :nom, null: false
      t.string :nom_long
      t.string :public_ou_prive
      t.string :type_organisation_privee
      t.string :site_internet
      t.string :grist_id, index: { unique: true }
      t.timestamps
    end

    create_table :types_acteurs do |t|
      t.string :nom, null: false
      t.text :description
      t.text :codes_juridiques
      t.string :slug
      t.string :grist_id, index: { unique: true }
      t.timestamps
    end

    create_table :vocabulaires do |t|
      t.string :nom, null: false
      t.string :categorie, null: false
      t.string :slug
      t.string :grist_id, index: { unique: true }
      t.timestamps
    end

    create_table :demarches do |t|
      t.string :nom, null: false
      t.string :icone
      t.text :description_courte
      t.text :contexte
      t.text :cadre_juridique
      t.string :mots_clefs, array: true, default: [], null: false
      t.string :slug, index: { unique: true }
      t.boolean :visible, null: false, default: false
      t.datetime :modifie_le
      t.string :grist_id, index: { unique: true }
      t.timestamps
    end

    create_table :solutions do |t|
      t.string :nom, null: false
      t.text :description_courte
      t.string :site_internet
      t.text :permet
      t.text :ne_permet_pas
      t.text :legende_image
      t.string :url_demande_acces
      t.string :uid_datagouv
      t.boolean :france_connectee, null: false, default: false
      t.string :categorie
      t.string :slug, index: { unique: true }
      t.boolean :visible, null: false, default: false
      t.datetime :modifie_le
      t.string :grist_id, index: { unique: true }
      t.timestamps
    end

    create_table :integrations do |t|
      t.references :integratrice, null: false, foreign_key: { to_table: :solutions }
      t.references :integree, null: false, foreign_key: { to_table: :solutions }
      t.string :type_integration, null: false
      t.string :statut
      t.text :notes
      t.string :grist_id, index: { unique: true }
      t.timestamps
    end

    create_table :recommandations do |t|
      t.references :demarche, null: false, foreign_key: true
      t.references :solution, null: false, foreign_key: true
      t.text :donnees_utiles
      t.text :parametres_a_saisir
      t.string :url_demande_acces
      t.boolean :visible, null: false, default: false
      t.datetime :modifie_le
      t.string :grist_id, index: { unique: true }
      t.timestamps
    end

    create_table :utilites do |t|
      t.references :demarche, null: false, foreign_key: true
      t.references :solution, null: false, foreign_key: true
      t.text :description
      t.integer :ordre
      t.string :grist_id, index: { unique: true }
      t.timestamps
    end
    add_index :utilites, [:demarche_id, :solution_id], unique: true

    create_join_table :demarches, :vocabulaires do |t|
      t.index [:demarche_id, :vocabulaire_id], unique: true
    end
    create_join_table :solutions, :vocabulaires do |t|
      t.index [:solution_id, :vocabulaire_id], unique: true
    end
    create_join_table :demarches, :types_acteurs do |t|
      t.index [:demarche_id, :type_acteur_id], unique: true
    end
    create_join_table :solutions, :types_acteurs do |t|
      t.index [:solution_id, :type_acteur_id], unique: true
    end
    create_join_table :organisations, :solutions do |t|
      t.index [:organisation_id, :solution_id], unique: true
    end
    create_join_table :demarches, :integrations do |t|
      t.index [:demarche_id, :integration_id], unique: true
    end
  end
end
