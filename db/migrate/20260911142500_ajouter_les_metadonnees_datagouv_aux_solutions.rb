class AjouterLesMetadonneesDatagouvAuxSolutions < ActiveRecord::Migration[8.1]
  def change
    change_table :solutions, bulk: true do |t|
      t.string :datagouv_titre
      t.string :datagouv_organisation
      t.string :datagouv_logo
      t.string :datagouv_acces
      t.string :datagouv_acces_acteurs_publics
    end
  end
end
