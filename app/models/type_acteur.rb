class TypeActeur < ApplicationRecord
  has_and_belongs_to_many :demarches
  has_and_belongs_to_many :solutions
end
