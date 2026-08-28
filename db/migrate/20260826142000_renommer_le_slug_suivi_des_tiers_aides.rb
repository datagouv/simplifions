class RenommerLeSlugSuiviDesTiersAides < ActiveRecord::Migration[8.1]
  # Le topic data.gouv a été renommé ; l'import ne touche jamais un slug déjà posé,
  # donc les bases importées avant le nouveau snapshot doivent être alignées à la main.
  def up
    execute <<~SQL
      UPDATE demarches
      SET slug = 'aides-publiques-entreprises-et-associations-suivi-des-tiers-aides'
      WHERE slug = 'aides-publiques-personnes-morales-et-entreprises-individuelles-suivi-des-tiers-aides'
    SQL
  end

  def down; end
end
