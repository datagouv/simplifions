class Solution < ApplicationRecord
  validates :nom, presence: true

  has_one_attached :image

  has_and_belongs_to_many :organisations
  has_and_belongs_to_many :vocabulaires
  has_and_belongs_to_many :types_acteurs, class_name: 'TypeActeur'
  has_many :recommandations, dependent: :destroy

  has_many :integrations_comme_integratrice, class_name: 'Integration', foreign_key: :integratrice_id,
    inverse_of: :integratrice, dependent: :destroy
  has_many :integrations_comme_integree, class_name: 'Integration', foreign_key: :integree_id,
    inverse_of: :integree, dependent: :destroy
  has_many :integrees, through: :integrations_comme_integratrice
  has_many :integratrices, through: :integrations_comme_integree
  has_many :exposees, -> { merge(Integration.expose) }, through: :integrations_comme_integratrice, source: :integree

  enum :categorie,
    %w[brique_logicielle api base_de_donnees site_de_consultation logiciel_metier_cle_en_main].index_with(&:itself),
    prefix: true

  scope :visibles, -> { where(visible: true) }

  def fiche? = !categorie_api? && !categorie_base_de_donnees?
end
