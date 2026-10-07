class AjouterUnBrouillonAuxFiches < ActiveRecord::Migration[8.1]
  def change
    add_column :demarches, :brouillon, :jsonb
    add_column :solutions, :brouillon, :jsonb
  end
end
