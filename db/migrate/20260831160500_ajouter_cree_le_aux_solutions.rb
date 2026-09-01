class AjouterCreeLeAuxSolutions < ActiveRecord::Migration[8.1]
  def change
    add_column :solutions, :cree_le, :datetime
  end
end
