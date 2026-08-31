class Solution < ApplicationRecord
  validates :nom, presence: true

  # Le contenu Grist est semi-confiance : seules les URLs http(s) sont conservées.
  normalizes :site_internet, :url_demande_acces,
    with: ->(url) { url.strip if url.to_s.strip.match?(%r{\Ahttps?://}i) }
  validates :description_courte, :site_internet, :permet, :ne_permet_pas, :legende_image,
    :url_demande_acces, :slug, :image, absence: true, unless: :fiche?

  has_one_attached :image

  has_and_belongs_to_many :organisations
  has_and_belongs_to_many :vocabulaires
  has_and_belongs_to_many :types_acteurs, class_name: 'TypeActeur'
  has_many :recommandations, dependent: :destroy

  has_many :integrations_comme_integratrice, class_name: 'Integration', foreign_key: :integratrice_id,
    inverse_of: :integratrice, dependent: :destroy
  has_many :integrations_comme_integree, class_name: 'Integration', foreign_key: :integree_id,
    inverse_of: :integree, dependent: :destroy
  has_many :integrees, through: :integrations_comme_integratrice
  has_many :integratrices, through: :integrations_comme_integree
  has_many :exposees, -> { merge(Integration.expose) }, through: :integrations_comme_integratrice, source: :integree
  has_many :consommees, -> { merge(Integration.consomme.en_production) },
    through: :integrations_comme_integratrice, source: :integree

  enum :categorie,
    %w[brique_logicielle api base_de_donnees site_de_consultation logiciel_metier_cle_en_main].index_with(&:itself),
    prefix: true

  scope :visibles, -> { where(visible: true) }

  def fiche? = !categorie_api? && !categorie_base_de_donnees?

  def privee? = organisations.any? { |organisation| organisation.public_ou_prive == 'Privé' }

  # Les données que la solution fournit : elle-même quand c'est une API, plus celles qu'elle expose.
  def fournies = [self, *exposees]

  def integratrices_visibles
    Solution.visibles.where(id: Integration.en_production.where(integree: fournies).select(:integratrice_id))
  end

  # { integratrice_id => { demarche visible => [intégrées, utiles] } } : pour chaque démarche où
  # l'intégratrice consomme en production une donnée fournie, x données marquées utiles sur y attendues.
  def couvertures
    utiles = Recommandation.niveau_1.where(solution: fournies).pluck(:demarche_id, :solution_id)
    y_par_demarche = utiles.map(&:first).tally

    Integration.en_production.where(integree: fournies).preload(:demarches)
      .each_with_object(Hash.new { |couvertures, id| couvertures[id] = {} }) do |integration, couvertures|
      integration.demarches.select(&:visible?).each do |demarche|
        y = y_par_demarche[demarche.id] || next
        cellule = couvertures[integration.integratrice_id][demarche] ||= [0, y]
        cellule[0] += 1 if utiles.include?([demarche.id, integration.integree_id])
      end
    end
  end

  # Même règle que le site actuel (formule Grist Recommande_pour_les_cas_d_usages) : démarches
  # recommandant la solution, plus celles où elle intègre en production une donnée d'une reco visible.
  def demarches_simplifiables
    Demarche.visibles.where(id: recommandations.visibles.select(:demarche_id))
      .or(Demarche.visibles.where(id: demarche_ids_integres))
  end

  private

  def demarche_ids_integres
    paires = integrations_comme_integratrice.en_production.joins(:demarches)
      .pluck(Arel.sql('demarches.id'), :integree_id)
    Recommandation.visibles.where(demarche_id: paires.map(&:first)).preload(solution: :exposees)
      .select { |reco| reco.solution.fournies.any? { |donnee| paires.include?([reco.demarche_id, donnee.id]) } }
      .map(&:demarche_id)
  end
end
