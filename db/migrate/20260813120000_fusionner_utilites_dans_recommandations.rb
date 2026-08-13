class FusionnerUtilitesDansRecommandations < ActiveRecord::Migration[8.1]
  def change
    add_column :recommandations, :description, :text
    add_column :recommandations, :niveau, :integer
    add_column :recommandations, :ordre, :integer
    add_index :recommandations, %i[demarche_id solution_id], unique: true
    drop_table :utilites

    execute "UPDATE solutions SET slug = NULL WHERE categorie IN ('api', 'base_de_donnees')"
  end
end
