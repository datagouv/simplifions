class Organisation < ApplicationRecord
  validates :nom, presence: true

  has_and_belongs_to_many :solutions
end
