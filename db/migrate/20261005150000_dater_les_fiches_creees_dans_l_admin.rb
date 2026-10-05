class DaterLesFichesCreeesDansLAdmin < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL.squish
        UPDATE demarches SET cree_le = created_at WHERE grist_id IS NULL AND cree_le IS NULL;
        UPDATE solutions SET cree_le = created_at WHERE grist_id IS NULL AND cree_le IS NULL;
      SQL
    end
  end

  def down; end
end
