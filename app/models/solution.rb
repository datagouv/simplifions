class Solution < ApplicationRecord
  CATEGORIES = {
    brique_logicielle: 'brique_logicielle',
    api: 'api',
    base_de_donnees: 'base_de_donnees',
    site_de_consultation: 'site_de_consultation',
    logiciel_metier_cle_en_main: 'logiciel_metier_cle_en_main'
  }.freeze

  has_one_attached :image

  has_and_belongs_to_many :organisations
  has_and_belongs_to_many :vocabulaires
  has_and_belongs_to_many :types_acteurs, class_name: 'TypeActeur'
  has_many :recommandations, dependent: :destroy
  has_many :utilites, dependent: :destroy

  has_many :integrations_comme_integratrice, class_name: 'Integration', foreign_key: :integratrice_id,
    inverse_of: :integratrice, dependent: :destroy
  has_many :integrations_comme_integree, class_name: 'Integration', foreign_key: :integree_id,
    inverse_of: :integree, dependent: :destroy
  has_many :integrees, through: :integrations_comme_integratrice
  has_many :integratrices, through: :integrations_comme_integree
  has_many :exposees, -> { merge(Integration.expose) }, through: :integrations_comme_integratrice, source: :integree

  enum :categorie, CATEGORIES, prefix: true

  scope :visibles, -> { where(visible: true) }
end
