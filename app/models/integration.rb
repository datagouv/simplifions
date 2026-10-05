class Integration < ApplicationRecord
  STATUT_EN_PRODUCTION = '✅ en production'.freeze
  STATUTS = ['💡 en prospection', '🚧 Intéressé si évolution', '⏳En attente de développement', '⚙️ en développement',
             '📦 en recette', STATUT_EN_PRODUCTION].freeze

  belongs_to :integratrice, class_name: 'Solution'
  belongs_to :integree, class_name: 'Solution'
  has_and_belongs_to_many :demarches

  enum :type_integration, %w[expose consomme].index_with(&:itself)
  normalizes :grist_id, with: ->(valeur) { valeur.presence }
  validates :grist_id, uniqueness: true, allow_nil: true
  validates :type_integration, presence: true
  validates :statut, inclusion: { in: STATUTS }, allow_blank: true
  validate { errors.add(:base, :solution_integree_elle_meme) if integratrice_id && integratrice_id == integree_id }

  scope :en_production, -> { where(statut: STATUT_EN_PRODUCTION) }
  def libelle = "#{integratrice.nom} → #{integree.nom} (#{self.class.human_attribute_name("type_integration.#{type_integration}").downcase})"

  scope :pour_demarche, ->(demarche) { joins(:demarches).where(demarches: { id: demarche }) }
end
