class Demarche < ApplicationRecord
  has_many :recommandations, dependent: :destroy
  has_many :utilites, dependent: :destroy
  has_and_belongs_to_many :vocabulaires
  has_and_belongs_to_many :types_acteurs, class_name: 'TypeActeur'
  has_and_belongs_to_many :integrations

  scope :visibles, -> { where(visible: true) }
end
