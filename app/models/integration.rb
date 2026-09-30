class Integration < ApplicationRecord
  STATUT_EN_PRODUCTION = '✅ en production'.freeze

  belongs_to :integratrice, class_name: 'Solution'
  belongs_to :integree, class_name: 'Solution'
  has_and_belongs_to_many :demarches

  enum :type_integration, %w[expose consomme].index_with(&:itself)
  normalizes :grist_id, with: ->(valeur) { valeur.presence }
  validates :grist_id, uniqueness: true, allow_nil: true
  validates :type_integration, presence: true

  scope :en_production, -> { where(statut: STATUT_EN_PRODUCTION) }
  def libelle = "#{integratrice.nom} → #{integree.nom} (#{type_integration})"

  scope :pour_demarche, ->(demarche) { joins(:demarches).where(demarches: { id: demarche }) }
end
