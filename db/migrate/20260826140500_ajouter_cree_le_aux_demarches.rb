class AjouterCreeLeAuxDemarches < ActiveRecord::Migration[8.1]
  def change
    add_column :demarches, :cree_le, :datetime
  end
end
