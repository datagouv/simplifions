class Integration < ApplicationRecord
  include Rangeable

  has_paper_trail

  STATUT_EN_PRODUCTION = '✅ en production'.freeze
  STATUTS = ['💡 en prospection', '🚧 Intéressé si évolution', '⏳En attente de développement', '⚙️ en développement',
             '📦 en recette', STATUT_EN_PRODUCTION].freeze
  TYPE_DE_LISTE = { 'fournies' => 'expose', 'integrees' => 'consomme' }.freeze

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
  def libelle = "#{integratrice&.libelle_admin} → #{integree&.libelle_admin} (#{type_libelle.downcase})"
  def type_libelle = self.class.human_attribute_name("type_integration.#{type_integration}")

  def self.ransackable_associations(_auth_object = nil) = %w[integratrice integree]
  scope :pour_demarche, ->(demarche) { joins(:demarches).where(demarches: { id: demarche }) }
  scope :par_libelle_admin_de, ->(cote) { joins(cote).merge(Solution.par_libelle_admin).order(:id) }

  def self.ordre_public = [arel_table[:ordre].asc.nulls_last, Arel.sql("COALESCE(NULLIF(BTRIM(solutions.datagouv_titre), ''), solutions.nom)")]
  scope :dans_l_ordre_public, -> { joins(:integree).order(ordre_public) }

  def deplacer_a(position) = expose? ? super : refuser_le_rangement
  def rangees = integratrice.integrations_qu_elle_expose.dans_l_ordre_public

  def demarches_autorisees = Demarche.where(id: Recommandation.where(solution_id: integree_id).select(:demarche_id))
  def autorisee_pour?(demarche) = Recommandation.exists?(demarche:, solution_id: integree_id)
  def demarches_proposees = demarches_autorisees.or(Demarche.where(id: demarche_ids))

  protected

  def ranger_a(rang) = (update!(ordre: rang) unless ordre == rang)

  private

  def refuser_le_rangement
    errors.add(:base, :pas_fournie)
    false
  end

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
