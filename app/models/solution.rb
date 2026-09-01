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
  scope :sur_datagouv, -> { where.not(uid_datagouv: [nil, '']) }

  def fiche? = !categorie_api? && !categorie_base_de_donnees?

  def privee? = organisations.any? { |organisation| organisation.public_ou_prive == 'Privé' }

  # Les données que la solution fournit : elle-même quand c'est une API, plus celles qu'elle expose.
  def fournies = [self, *exposees]

  def integratrices_visibles
    Solution.visibles.where(id: Integration.en_production.where(integree: fournies).select(:integratrice_id))
  end

  # Nombre de données intégrées en production par chaque intégratrice visible, tous fournisseurs confondus.
  def nb_donnees_integrees
    Integration.consomme.en_production.where(integratrice: integratrices_visibles).group(:integratrice_id).count
  end

  def lien_datagouv
    "https://www.data.gouv.fr/fr/#{categorie_base_de_donnees? ? 'datasets' : 'dataservices'}/#{uid_datagouv}"
  end

  # { integratrice_id => { demarche visible => [intégrées, utiles] } } : pour chaque démarche où
  # l'intégratrice visible consomme en production une donnée fournie, x données marquées utiles sur y attendues.
  def couvertures
    paires_integrees.each_with_object({}) do |(integratrice_id, demarche, integree_id), couvertures|
      y = y_par_demarche[demarche.id] || next
      cellule = (couvertures[integratrice_id] ||= {})[demarche] ||= [0, y]
      cellule[0] += 1 if paires_utiles.include?([demarche.id, integree_id])
    end
  end

  # Même règle et même ordre que le site actuel (formule Grist Recommande_pour_les_cas_d_usages) :
  # démarches recommandant la solution, dans l'ordre de saisie des recommandations, puis celles
  # où elle intègre en production une donnée d'une reco visible.
  def demarches_simplifiables
    ordre = recommandations.visibles.order(:id).pluck(:demarche_id) + demarche_ids_integres
    Demarche.visibles.where(id: ordre).sort_by { |demarche| ordre.index(demarche.id) }
  end

  private

  # [demarche_id, solution_id] des données fournies marquées utiles pour une démarche (le « y » attendu)
  def paires_utiles
    @paires_utiles ||= Recommandation.niveau_1.where(solution: fournies).pluck(:demarche_id, :solution_id).to_set
  end

  def y_par_demarche
    @y_par_demarche ||= paires_utiles.map(&:first).tally
  end

  # [integratrice_id, demarche visible, integree_id] des intégrations en production des données fournies
  def paires_integrees
    Integration.en_production.where(integree: fournies, integratrice: Solution.visibles)
      .preload(:demarches).flat_map do |integration|
        integration.demarches.select(&:visible?)
          .map { |demarche| [integration.integratrice_id, demarche, integration.integree_id] }
      end
  end

  def demarche_ids_integres
    integrees = integrations_comme_integratrice.en_production.joins(:demarches)
      .pluck(Arel.sql('demarches.id'), :integree_id).to_set
    Recommandation.visibles.preload(solution: :exposees)
      .filter_map { |reco| reco.demarche_id if integre_pour?(reco, integrees) }
  end

  def integre_pour?(reco, integrees)
    reco.solution.fournies.any? { |donnee| integrees.include?([reco.demarche_id, donnee.id]) }
  end
end
