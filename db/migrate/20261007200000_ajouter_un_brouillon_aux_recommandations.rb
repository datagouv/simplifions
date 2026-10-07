class AjouterUnBrouillonAuxRecommandations < ActiveRecord::Migration[8.1]
  def change
    add_column :recommandations, :brouillon, :jsonb
  end
end
