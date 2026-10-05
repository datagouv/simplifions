class ExigerUnNiveauDeRecommandation < ActiveRecord::Migration[8.1]
  def change
    safety_assured { change_column_null :recommandations, :niveau, false }
  end
end
