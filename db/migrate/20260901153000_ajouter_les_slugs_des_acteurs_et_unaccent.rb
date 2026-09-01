class AjouterLesSlugsDesActeursEtUnaccent < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'unaccent'
    add_column :types_acteurs, :slugs, :string, array: true, default: [], null: false
    reversible do |dir|
      dir.up { execute "UPDATE types_acteurs SET slugs = ARRAY[slug] WHERE slug IS NOT NULL" }
    end
    remove_column :types_acteurs, :slug, :string
  end
end
