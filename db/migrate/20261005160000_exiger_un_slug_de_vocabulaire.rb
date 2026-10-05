class ExigerUnSlugDeVocabulaire < ActiveRecord::Migration[8.1]
  def change
    safety_assured { change_column_null :vocabulaires, :slug, false }
  end
end
