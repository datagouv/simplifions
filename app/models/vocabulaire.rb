class Vocabulaire < ApplicationRecord
  # Libellés affichés par le site actuel (noms des tags data.gouv) là où le Label Grist porte des emojis.
  LIBELLES = {
    'acces-facile' => 'Accès facile',
    'dlnuf' => 'Dites-le nous une fois',
    'proactivite' => 'Proactivité',
    'brique-technique' => 'API, jeu de données ou brique logicielle',
    'logiciel-metier' => 'Logiciel métier "clé en main"',
    'portail-consultation' => 'Site de consultation'
  }.freeze

  validates :nom, presence: true

  has_and_belongs_to_many :demarches
  has_and_belongs_to_many :solutions

  enum :categorie, %w[usager type_simplification solution].index_with(&:itself), prefix: true

  def libelle = LIBELLES[slug] || nom
end
