class SupprimerNotesDesIntegrations < ActiveRecord::Migration[8.1]
  def change
    remove_column :integrations, :notes, :text
  end
end
