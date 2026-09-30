class Organisation < ApplicationRecord
  validates :nom, presence: true
  normalizes :grist_id, with: ->(valeur) { valeur.presence }
  validates :grist_id, uniqueness: true, allow_nil: true

  has_and_belongs_to_many :solutions
end
