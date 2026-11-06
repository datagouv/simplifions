class Demarche < ApplicationRecord
  include Brouillonnable

  has_paper_trail ignore: %i[modifie_le brouillon]

  validates :nom, presence: true
  normalizes :grist_id, :slug, with: ->(valeur) { valeur.presence }
  validates :grist_id, :slug, uniqueness: true, allow_nil: true
  validates :slug, format: { with: FORMAT_SLUG, message: :format_slug }, allow_nil: true
  validates :slug, presence: true, if: :visible?

  has_many :recommandations, dependent: :destroy
  has_and_belongs_to_many :vocabulaires
  has_and_belongs_to_many :types_acteurs, class_name: 'TypeActeur'
  has_and_belongs_to_many :integrations, before_add: :ecarte_si_hors_regle
  validate { integrations_ecartees.each { errors.add(:base, :integration_hors_regle, libelle: it.libelle) } }

  scope :visibles, -> { where(visible: true) }
  scope :en_brouillon, -> { where.not(brouillon: nil).or(where(id: Recommandation.en_brouillon.select(:demarche_id))) }
  def page_publique? = visible? && slug.present?
  def titre = "#{icone} #{nom}".strip
  def chapo = description_courte.to_s.lines.first&.strip
  def usagers = vocabulaires.select(&:categorie_usager?).map(&:nom)
  def acteurs = types_acteurs.map(&:nom).sort

  scope :recherche, ->(q) { chaque_mot_dans("unaccent(concat_ws(' ', nom, description_courte, array_to_string(mots_clefs, ' '))) ILIKE unaccent(:motif)", q) }
  def self.ransackable_attributes(_auth_object = nil) = %w[nom]
  def self.ransackable_scopes(_auth_object = nil) = %w[recherche en_brouillon]

  TRIS = { '-created' => { cree_le: :desc }, '-last_modified' => { modifie_le: :desc } }.freeze

  scope :pour_vocabulaire, ->(slug) { where(id: Demarche.joins(:vocabulaires).where(vocabulaires: { slug: })) if slug.present? }
  scope :pour_acteur, ->(slug) { where(id: Demarche.joins(:types_acteurs).where('? = ANY(types_acteurs.slugs)', slug)) if slug.present? }

  def self.catalogue(params)
    visibles.pour_vocabulaire(params['target-users']).pour_vocabulaire(params['types-de-simplification'])
      .pour_vocabulaire(params['categorie-de-solution']).pour_acteur(params['fournisseurs-de-service'])
      .recherche(params['q']).order(TRIS.fetch(params['sort'], {})).order(:id)
  end

  def mots_clefs=(valeur)
    super(valeur.is_a?(String) ? valeur.lines.map(&:strip).compact_blank : valeur)
  end

  delegate :en_brouillon, to: :recommandations, prefix: :recommandations

  def en_brouillon? = brouillon? || recommandations_en_brouillon.exists?
  def date_du_brouillon = [super, *recommandations_en_brouillon.map(&:date_du_brouillon)].compact.max
  def brouillon_abandonnable? = brouillon? || recommandations.a_publier_avec_la_demarche.exists?
  def suppression_sans_retour_a_annoncer? = visible? || brouillon_abandonnable?

  def enregistrer(attributs)
    return super unless publication_demandee?(attributs)

    transaction { (super && publier_les_recommandations) || raise(ActiveRecord::Rollback) } || false
  end

  def abandonner_brouillon!
    transaction do
      recommandations.a_publier_avec_la_demarche.each(&:abandonner_avec_la_demarche!)
      super
    end
  end

  def previsualiser
    @apercu = true
    super
  end

  def recommandations_publiees
    @recommandations_publiees ||= @apercu ? cartes_telles_que_publiees : recommandations.visibles.niveau_2.includes(solution: %i[exposees organisations]).order(:ordre, :id).to_a
  end

  def groupes_donnees_utiles
    @groupes_donnees_utiles ||= begin
      seules, bouquets = recommandations_publiees.select { it.donnees_attendues.any? }.partition { !it.solution.fiche? }
      autres = seules.flat_map(&:donnees_attendues)
      bouquets.map { [it.solution.nom, it.donnees_attendues, [it]] } + (autres.any? ? [[nil, autres, seules]] : [])
    end
  end

  def donnees_utiles = groupes_donnees_utiles.flat_map(&:second)

  def couverture_du_groupe(recommandations, solution) = recommandations.map { it.couverture(solution.id) }.transpose.map(&:sum)

  def integrees_par(solution) = recommandations_publiees.flat_map { it.integrees.fetch(solution.id, []) }.to_set

  def couverture(solution)
    integrees = integrees_par(solution)
    [donnees_utiles.count { integrees.include?(it.id) }, donnees_utiles.size]
  end

  def integratrices = Solution.where(id: recommandations_publiees.flat_map { it.solutions_integratrices.ids }).includes(:organisations)

  def integratrices_par_categorie
    nombres = integratrices.index_with { couverture(it).first }.select { |_solution, nombre| nombre.positive? }
    nombres.keys.sort_by { [-nombres[it], I18n.transliterate(it.nom).downcase] }
      .group_by(&:categorie).slice(*Solution::CATEGORIES_INTEGRATRICES).transform_keys(&:to_sym)
  end

  def integrations_autorisees = Integration.where(integree_id: recommandations.select(:solution_id))
  def integrations_proposees = integrations_autorisees.or(Integration.where(id: integration_ids))

  private

  def cartes_telles_que_publiees
    utiles, cartes = recommandations_telles_que_publiees.partition(&:niveau_1?)
    cartes.select(&:visible?).sort_by { [it.ordre || Float::INFINITY, it.id] }.each do |carte|
      carte.apis_utiles = utiles.select { it.solution.in?(carte.solution.fournies) }.sort_by { rang_de_donnee_utile(it) }
    end
  end

  def rang_de_donnee_utile(utile)
    [utile.ordre || Float::INFINITY, utile.description ? -utile.description.length : 1, I18n.transliterate(utile.solution.nom).downcase]
  end

  def recommandations_telles_que_publiees
    a_publier = recommandations_en_brouillon.ids
    recommandations.includes(solution: %i[exposees organisations]).to_a.each { it.appliquer_brouillon if it.id.in?(a_publier) }
  end

  def publier_les_recommandations
    refusee = recommandations_en_brouillon.find { !it.publier_avec_la_demarche }
    return true unless refusee

    errors.add(:base, :recommandation_refusee, libelle: refusee.solution&.libelle_admin, erreurs: refusee.errors.full_messages.to_sentence)
    false
  end

  def integrations_ecartees = @integrations_ecartees ||= []

  def ecarte_si_hors_regle(integration)
    return if integration.autorisee_pour?(self)

    integrations_ecartees << integration
    throw :abort
  end
end
