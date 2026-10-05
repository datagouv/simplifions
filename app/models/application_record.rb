class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  FORMAT_SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  def self.chaque_mot_dans(condition, recherche)
    recherche.to_s.split.reduce(all) { |liste, terme| liste.where(condition, motif: "%#{sanitize_sql_like(terme)}%") }
  end

  scope :nom_contient, ->(q) { chaque_mot_dans('unaccent(nom) ILIKE unaccent(:motif)', q) }
end
