class Organisation < ApplicationRecord
  PUBLIC_OU_PRIVE = %w[Public Privé].freeze

  validates :nom, presence: true
  normalizes :grist_id, with: ->(valeur) { valeur.presence }
  validates :grist_id, uniqueness: true, allow_nil: true
  validates :public_ou_prive, inclusion: { in: PUBLIC_OU_PRIVE }, allow_blank: true

  has_and_belongs_to_many :solutions

  def publique? = public_ou_prive == 'Public'

  def solutions_rendues_privees
    return Solution.none unless publique?

    autres_publiques = Organisation.where(public_ou_prive: 'Public').where.not(id:)
    solutions.fiches.where.not(id: Solution.joins(:organisations).merge(autres_publiques))
  end
end
