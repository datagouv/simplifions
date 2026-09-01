class TypeActeur < ApplicationRecord
  # Les regroupements proposés en filtre par le site actuel (config du front-kit), dans son ordre.
  FILTRES = {
    'communes' => 'Communes et groupements de communes',
    'departements' => 'Départements',
    'regions' => 'Régions',
    'tout-collectivites-territoires' => 'Toutes les collectivités et territoires',
    'etat' => 'État',
    'organismes-droit-prive' => 'Organismes de droit privé',
    'acteurs-education-enseignement' => "Acteurs de l'éducation et de l'enseignement",
    'acteurs-transport' => 'Acteurs du transport',
    'tout-acteurs-publics' => 'Tous les acteurs publics'
  }.freeze

  validates :nom, presence: true

  has_and_belongs_to_many :demarches
  has_and_belongs_to_many :solutions
end
