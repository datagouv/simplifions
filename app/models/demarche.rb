class Demarche < ApplicationRecord
  validates :nom, presence: true

  has_many :recommandations, dependent: :destroy
  has_and_belongs_to_many :vocabulaires
  has_and_belongs_to_many :types_acteurs, class_name: 'TypeActeur'
  has_and_belongs_to_many :integrations

  scope :visibles, -> { where(visible: true) }
  def usagers = vocabulaires.select(&:categorie_usager?).map(&:nom)
  def acteurs = types_acteurs.map(&:nom).sort

  scope :recherche, lambda { |q|
    q.to_s.split.reduce(all) do |liste, terme|
      liste.where("unaccent(concat_ws(' ', nom, description_courte, array_to_string(mots_clefs, ' '))) ILIKE unaccent(?)",
        "%#{sanitize_sql_like(terme)}%")
    end
  }

  TRIS = { '-created' => { cree_le: :desc }, '-last_modified' => { modifie_le: :desc } }.freeze

  scope :pour_vocabulaire, ->(slug) { where(id: joins(:vocabulaires).where(vocabulaires: { slug: })) if slug.present? }
  scope :pour_acteur, ->(slug) { where(id: joins(:types_acteurs).where('? = ANY(types_acteurs.slugs)', slug)) if slug.present? }

  # Mêmes paramètres et mêmes valeurs que les tags des topics du site actuel.
  def self.catalogue(params)
    visibles.pour_vocabulaire(params['target-users']).pour_vocabulaire(params['types-de-simplification'])
      .pour_vocabulaire(params['categorie-de-solution']).pour_acteur(params['fournisseurs-de-service'])
      .recherche(params['q']).order(TRIS.fetch(params['sort'], {})).order(:id)
  end
end
