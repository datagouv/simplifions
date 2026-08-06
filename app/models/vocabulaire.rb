class Vocabulaire < ApplicationRecord
  has_and_belongs_to_many :demarches
  has_and_belongs_to_many :solutions

  enum :categorie, { usager: 'usager', type_simplification: 'type_simplification' }, prefix: true
end
