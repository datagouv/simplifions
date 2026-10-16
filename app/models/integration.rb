class Integration < ApplicationRecord
  has_paper_trail

  STATUT_EN_PRODUCTION = '✅ en production'.freeze
  STATUTS = ['💡 en prospection', '🚧 Intéressé si évolution', '⏳En attente de développement', '⚙️ en développement',
             '📦 en recette', STATUT_EN_PRODUCTION].freeze

  belongs_to :integratrice, class_name: 'Solution'
  belongs_to :integree, class_name: 'Solution'
  has_and_belongs_to_many :demarches, before_add: :ecarte_si_hors_regle

  enum :type_integration, %w[expose consomme].index_with(&:itself)
  normalizes :grist_id, with: ->(valeur) { valeur.presence }
  validates :grist_id, uniqueness: true, allow_nil: true
  validates :type_integration, presence: true
  validates :statut, inclusion: { in: STATUTS }, allow_blank: true
  validate { errors.add(:base, :solution_integree_elle_meme) if integratrice_id && integratrice_id == integree_id }
  validate { demarches_hors_regle.each { errors.add(:base, :demarche_hors_regle, nom: it.nom) } }

  scope :en_production, -> { where(statut: STATUT_EN_PRODUCTION) }
  def libelle = "#{integratrice.libelle_admin} → #{integree.libelle_admin} (#{type_libelle.downcase})"
  def type_libelle = self.class.human_attribute_name("type_integration.#{type_integration}")

  def self.ransackable_associations(_auth_object = nil) = %w[integratrice integree]

  def self.integrees_par_integratrice(integree_ids)
    consomme.en_production.where(integree_id: integree_ids).distinct.pluck(:integratrice_id, :integree_id)
      .group_by(&:first).transform_values { |paires| paires.to_set(&:last) }
  end

  scope :pour_demarche, ->(demarche) { joins(:demarches).where(demarches: { id: demarche }) }
  scope :par_libelle_admin_de, ->(cote) { joins(cote).merge(Solution.par_libelle_admin).order(:id) }

  def demarches_autorisees = Demarche.where(id: Recommandation.where(solution_id: integree_id).select(:demarche_id))
  def autorisee_pour?(demarche) = Recommandation.exists?(demarche:, solution_id: integree_id)
  def demarches_proposees = demarches_autorisees.or(Demarche.where(id: demarche_ids))

  private

  def demarches_ecartees = @demarches_ecartees ||= []

  def demarches_hors_regle
    gardees = integree_id_changed? ? demarches.reject { autorisee_pour?(it) } : []
    demarches_ecartees | gardees
  end

  def ecarte_si_hors_regle(demarche)
    return if autorisee_pour?(demarche)

    demarches_ecartees << demarche
    throw :abort
  end
end
