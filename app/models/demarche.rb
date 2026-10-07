class Demarche < ApplicationRecord
  has_paper_trail ignore: %i[modifie_le]

  validates :nom, presence: true
  normalizes :grist_id, :slug, with: ->(valeur) { valeur.presence }
  validates :grist_id, :slug, uniqueness: true, allow_nil: true
  validates :slug, format: { with: FORMAT_SLUG, message: :format_slug }, allow_nil: true
  validates :slug, presence: true, if: :visible?

  has_many :recommandations, dependent: :destroy
  has_and_belongs_to_many :vocabulaires
  has_and_belongs_to_many :types_acteurs, class_name: 'TypeActeur'
  has_and_belongs_to_many :integrations, before_add: :ecarte_si_hors_regle
  validate { integrations_ecartees.each { errors.add(:base, :integration_hors_regle, libelle: it.libelle) } }

  scope :visibles, -> { where(visible: true) }
  def titre = "#{icone} #{nom}".strip
  def chapo = description_courte.to_s.lines.first&.strip
  def usagers = vocabulaires.select(&:categorie_usager?).map(&:nom)
  def acteurs = types_acteurs.map(&:nom).sort

  scope :recherche, ->(q) { chaque_mot_dans("unaccent(concat_ws(' ', nom, description_courte, array_to_string(mots_clefs, ' '))) ILIKE unaccent(:motif)", q) }
  def self.ransackable_attributes(_auth_object = nil) = %w[nom]
  def self.ransackable_scopes(_auth_object = nil) = %w[recherche]

  TRIS = { '-created' => { cree_le: :desc }, '-last_modified' => { modifie_le: :desc } }.freeze

  scope :pour_vocabulaire, ->(slug) { where(id: Demarche.joins(:vocabulaires).where(vocabulaires: { slug: })) if slug.present? }
  scope :pour_acteur, ->(slug) { where(id: Demarche.joins(:types_acteurs).where('? = ANY(types_acteurs.slugs)', slug)) if slug.present? }

  # Mêmes paramètres et mêmes valeurs que les tags des topics du site actuel.
  def self.catalogue(params)
    visibles.pour_vocabulaire(params['target-users']).pour_vocabulaire(params['types-de-simplification'])
      .pour_vocabulaire(params['categorie-de-solution']).pour_acteur(params['fournisseurs-de-service'])
      .recherche(params['q']).order(TRIS.fetch(params['sort'], {})).order(:id)
  end

  def mots_clefs=(valeur)
    super(valeur.is_a?(String) ? valeur.lines.map(&:strip).compact_blank : valeur)
  end

  def integrations_autorisees = Integration.where(integree_id: recommandations.select(:solution_id))

  private

  def integrations_ecartees = @integrations_ecartees ||= []

  def ecarte_si_hors_regle(integration)
    return if integration.autorisee_pour?(self)

    integrations_ecartees << integration
    throw :abort
  end
end
