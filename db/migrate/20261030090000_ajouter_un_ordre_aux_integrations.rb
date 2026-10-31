class AjouterUnOrdreAuxIntegrations < ActiveRecord::Migration[8.1]
  def change
    add_column :integrations, :ordre, :integer
  end
end
