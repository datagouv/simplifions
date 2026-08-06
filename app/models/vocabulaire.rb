class Vocabulaire < ApplicationRecord
  validates :nom, presence: true

  has_and_belongs_to_many :demarches
  has_and_belongs_to_many :solutions

  enum :categorie, %w[usager type_simplification].index_with(&:itself), prefix: true
end
