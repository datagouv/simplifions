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
    self.brouillon = { 'visible' => '1', 'modifie_le' => modifie_le, 'commence_le' => Time.current } if demarche&.visible?
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

  def couvertures
    return {} if donnees_attendues.empty?

    solutions_integratrices.ids.index_with { |integratrice_id| couverture(integratrice_id) }
  end

  def couverture(integratrice_id) = [integrees.fetch(integratrice_id, []).size, donnees_attendues.size]

  def integrees
    @integrees ||= Integration.consomme.en_production.where(integree_id: donnees_attendues.map(&:id))
      .distinct.pluck(:integratrice_id, :integree_id)
      .group_by(&:first).transform_values { |paires| paires.map(&:last) }
  end

  def donnees_attendues
    @donnees_attendues ||= solution.fiche? ? apis_utiles.map(&:solution) : [solution]
  end

  def moyens_acces
    solutions_integratrices.order(:nom)
      .sort_by.with_index { |solution, rang_par_nom| [-integrees.fetch(solution.id, []).size, rang_par_nom] }
      .group_by(&:categorie)
  end

  def apis_utiles
    @apis_utiles ||= utiles.joins(:solution).preload(solution: :organisations)
      .order(Arel.sql('recommandations.ordre ASC NULLS LAST, length(recommandations.description) DESC NULLS LAST, solutions.nom ASC')).to_a
  end

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
