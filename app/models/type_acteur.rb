class TypeActeur < ApplicationRecord
  # Les regroupements proposés en filtre par le site actuel (config du front-kit), dans son ordre : libellé => slug.
  FILTRES = {
    'Communes et groupements de communes' => 'communes',
    'Départements' => 'departements',
    'Régions' => 'regions',
    'Toutes les collectivités et territoires' => 'tout-collectivites-territoires',
    'État' => 'etat',
    'Organismes de droit privé' => 'organismes-droit-prive',
    "Acteurs de l'éducation et de l'enseignement" => 'acteurs-education-enseignement',
    'Acteurs du transport' => 'acteurs-transport',
    'Tous les acteurs publics' => 'tout-acteurs-publics'
  }.freeze

  validates :nom, presence: true
  def self.ransackable_attributes(_auth_object = nil) = %w[nom]
  normalizes :grist_id, with: ->(valeur) { valeur.presence }
  validates :grist_id, uniqueness: true, allow_nil: true

  has_and_belongs_to_many :demarches
  has_and_belongs_to_many :solutions

  def slugs=(valeur)
    super(Array(valeur) & FILTRES.values)
  end

  def regroupements = slugs.filter_map { |slug| FILTRES.key(slug) }
end
