class Recommandation < ApplicationRecord
  belongs_to :demarche
  belongs_to :solution

  enum :niveau, { niveau_1: 1, niveau_2: 2 }

  validates :solution_id, uniqueness: { scope: :demarche_id }

  scope :visibles, -> { where(visible: true) }

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

    Integration.consomme.en_production.where(integree_id: utiles.select(:solution_id))
      .group(:integratrice_id).distinct.count(:integree_id).transform_values { |x| [x, y] }
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

  def utiles = demarche.recommandations.niveau_1.where(solution: solution.fournies)

  def ne_recommande_pas_de_solution_privee
    errors.add(:solution, 'une solution privée ne peut pas être mise en avant') if solution&.privee?
  end
end
