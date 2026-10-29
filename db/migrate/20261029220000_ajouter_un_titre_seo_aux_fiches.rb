class AjouterUnTitreSeoAuxFiches < ActiveRecord::Migration[8.1]
  def change
    add_column :demarches, :titre_seo, :string
    add_column :solutions, :titre_seo, :string
  end
end
