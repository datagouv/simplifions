class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  FORMAT_SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  def self.chaque_mot_dans(condition, recherche)
    recherche.to_s.split.reduce(all) { |liste, terme| liste.where(condition, motif: "%#{sanitize_sql_like(terme)}%") }
  end

  def self.rechercher(recherche, *conditions)
    ransack(g: recherche.to_s.split.map { |mot| conditions.index_with(mot).merge(m: 'or') }).result
  end

  ransacker(:nom) { |parent| Arel::Nodes::NamedFunction.new('unaccent', [parent.table[:nom]]) }

  def self.ransackable_attributes(_auth_object = nil) = []
  def self.ransackable_associations(_auth_object = nil) = []
end
