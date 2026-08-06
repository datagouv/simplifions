class Integration < ApplicationRecord
  STATUT_EN_PRODUCTION = '✅ en production'.freeze

  belongs_to :integratrice, class_name: 'Solution'
  belongs_to :integree, class_name: 'Solution'
  has_and_belongs_to_many :demarches

  enum :type_integration, { expose: 'expose', consomme: 'consomme', authentifie: 'authentifie' }

  scope :en_production, -> { where(statut: STATUT_EN_PRODUCTION) }
  scope :pour_demarche, ->(demarche) { joins(:demarches).where(demarches: { id: demarche }) }
end
