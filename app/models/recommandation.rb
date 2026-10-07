class Recommandation < ApplicationRecord
  include Brouillonnable

  has_paper_trail ignore: %i[modifie_le brouillon]

  belongs_to :demarche
  belongs_to :solution

  enum :niveau, { niveau_1: 1, niveau_2: 2 }
  validates :niveau, presence: true
  normalizes :grist_id, with: ->(valeur) { valeur.presence }
  validates :grist_id, uniqueness: true, allow_nil: true

  validates :solution_id, uniqueness: { scope: :demarche_id }

  scope :visibles, -> { where(visible: true) }
  scope :a_publier_avec_la_demarche, -> { where("recommandations.brouillon->>'visible' = '1'") }
  scope :parues, -> { where.not(id: a_publier_avec_la_demarche) }
  scope :en_brouillon, -> { where.not(brouillon: nil).where(visible: true).or(a_publier_avec_la_demarche) }
  scope :par_niveau_et_ordre, -> { order(:niveau, :ordre, :id) }
  def libelle = "#{demarche.nom} → #{solution.libelle_admin}"

  def self.ransackable_associations(_auth_object = nil) = %w[demarche solution]

  def enregistrer(attributs)
    return super unless new_record? && !publication_demandee?(attributs)

    assign_attributes(attributs)
    self.brouillon = { 'visible' => '1', 'modifie_le' => modifie_le } if demarche&.visible?
    save
  end

  validate :ne_recommande_pas_de_solution_privee

  def solutions_integratrices
    Solution.visibles.where(
      id: Integration.en_production.pour_demarche(demarche)
        .where(integree: solution.fournies)
        .select(:integratrice_id)
    )
  end

  # { integratrice_id => [x, y] } : comme sur le site actuel, x données utiles intégrées en production sur les y
  # attendues, quelle que soit la démarche saisie sur l'intégration.
  def couvertures
    y = utiles.count
    return {} if y.zero?

    integrees = Integration.consomme.en_production.where(integree_id: utiles.select(:solution_id))
      .group(:integratrice_id).distinct.count(:integree_id)
    solutions_integratrices.ids.index_with { |integratrice_id| [integrees.fetch(integratrice_id, 0), y] }
  end

  def moyens_acces
    solutions_integratrices.order(:nom).group_by(&:categorie)
  end

  # Même ordre que le site actuel : ordre éditorial, puis description la plus fournie, puis nom
  def apis_utiles
    utiles.joins(:solution).preload(:solution)
      .order(Arel.sql('recommandations.ordre ASC NULLS LAST, length(recommandations.description) DESC NULLS LAST, solutions.nom ASC'))
  end

  # Le contenu Grist est semi-confiance : seules les URLs http(s) deviennent des liens
  def lien_demande_acces
    uri = begin
      URI.parse((url_demande_acces.presence || solution.url_demande_acces).to_s)
    rescue URI::InvalidURIError
      nil
    end
    return unless uri&.scheme&.in?(%w[http https])

    uri.query = [uri.query, "use_case=#{demarche.slug}"].compact.join('&')
    uri.to_s
  end

  private

  def utiles = demarche.recommandations.niveau_1.parues.where(solution: solution.fournies)

  def ne_recommande_pas_de_solution_privee
    errors.add(:solution, :privee) if solution&.privee?
  end
end
