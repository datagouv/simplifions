class IndexerLesTablesDeJointure < ActiveRecord::Migration[8.1]
  def change
    add_index :demarches_integrations, :integration_id
    add_index :demarches_types_acteurs, :type_acteur_id
    add_index :demarches_vocabulaires, :vocabulaire_id
    add_index :organisations_solutions, :solution_id
    add_index :solutions_types_acteurs, :type_acteur_id
    add_index :solutions_vocabulaires, :vocabulaire_id
    remove_index :recommandations, :demarche_id
  end
end
