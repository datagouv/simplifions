class Recommandation < ApplicationRecord
  include Brouillonnable
  include Rangeable

  has_paper_trail ignore: %i[modifie_le brouillon]

  belongs_to :demarche
  belongs_to :solution

  enum :niveau, { niveau_1: 1, niveau_2: 2 }
  validates :niveau, presence: true
  normalizes :grist_id, with: ->(valeur) { valeur.presence }
  validates :grist_id, uniqueness: true, allow_nil: true

  validates :solution_id, uniqueness: { scope: :demarche_id }

  attribute :retiree, :boolean, default: false

  scope :visibles, -> { where(visible: true) }
  scope :a_publier_avec_la_demarche, -> { where("recommandations.brouillon->>'visible' = '1'") }
  scope :retirees, -> { where("recommandations.brouillon->>'retiree' = '1'") }
  scope :parues, -> { where.not(id: a_publier_avec_la_demarche) }
  scope :en_brouillon, -> { where.not(brouillon: nil).where(visible: true).or(a_publier_avec_la_demarche) }
  scope :par_niveau_et_ordre, -> { order(:niveau, :ordre, :id) }
  def libelle = "#{demarche&.nom} → #{solution&.libelle_admin}"

  def self.sur_la_fiche = includes(:solution).map(&:appliquer_brouillon).sort_by { [it.ordre ? 0 : 1, it.ordre.to_i, it.id] }
  def rangees = demarche.recommandations.sur_la_fiche.select { it.niveau == niveau }
  def ajoutee_au_brouillon? = brouillon.to_h['visible'] == '1'
  def masquee? = !visible_in_database && !ajoutee_au_brouillon?
  def retrait_en_attente? = brouillon.to_h['retiree'] == '1'
  def retrait_a_publier? = demarche.visible? && visible? && !ajoutee_au_brouillon?
  def retrait_sans_retour_a_annoncer? = !retrait_a_publier? && demarche.suppression_sans_retour_a_annoncer?

  def retirer = retrait_a_publier? ? enregistrer('retiree' => '1', 'modifie_le' => Time.current) : destroy!

  def self.ransackable_associations(_auth_object = nil) = %w[demarche solution]

  def enregistrer(attributs)
    attributs = sans_retrait_si_masquee(sans_publication_de_donnee_utile(attributs))
    return publier_avec_la_demarche if retrait_en_attente? && publication_demandee?(attributs)
    return super if publication_demandee?(attributs)
    return enregistrer_brouillon(attributs.merge('visible' => '1')) if devient_donnee_utile?(attributs)
    return super unless new_record?

    assign_attributes(attributs)
    self.brouillon = { 'visible' => '1', 'modifie_le' => modifie_le, 'commence_le' => Time.current }
    save
  end

  def publier_avec_la_demarche = appliquer_brouillon.retiree? ? destroy! : ecrire('visible' => '1')

  def abandonner_avec_la_demarche!
    created_at >= brouillon['commence_le'].to_time ? destroy! : abandonner_brouillon!
  end

  validate :ne_recommande_pas_de_solution_privee

  attr_writer :apis_utiles

  def solutions_integratrices
    Solution.visibles.where(
      id: Integration.en_production.where(id: demarche.integration_ids)
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

  protected

  def ranger_a(rang)
    return if ordre == rang

    en_base = Recommandation.find(id)
    en_base.enregistrer('ordre' => rang, 'modifie_le' => Time.current) || raise(ActiveRecord::RecordInvalid, en_base)
  end

  private

  def sans_publication_de_donnee_utile(attributs)
    attributs = attributs.to_h.stringify_keys
    return attributs unless publication_demandee?(attributs) && attributs.fetch('niveau', niveau) == 'niveau_1'

    attributs.except('visible')
  end

  def sans_retrait_si_masquee(attributs) = retrait_en_attente? && attributs['visible'] == '0' ? attributs.merge('retiree' => '0') : attributs

  def devient_donnee_utile?(attributs)
    persisted? && niveau_2? && !visible? && attributs['niveau'] == 'niveau_1'
  end

  def utiles = demarche.recommandations.niveau_1.parues.where(solution: solution.fournies)

  def ne_recommande_pas_de_solution_privee
    errors.add(:solution, :privee) if solution&.privee?
  end
end
