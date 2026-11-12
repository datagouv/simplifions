class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  FORMAT_SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  def self.slug_du_nom(nom) = nom.to_s.tr('_', ' ').parameterize

  def self.chaque_mot_dans(condition, recherche)
    recherche.to_s.split.reduce(all) { |liste, terme| liste.where(condition, motif: "%#{sanitize_sql_like(terme)}%") }
  end

  def self.rechercher(recherche, *conditions)
    ransack(g: recherche.to_s.split.map { |mot| conditions.index_with(mot).merge(m: 'or') }).result
  end

  ransacker(:nom) { |parent| Arel::Nodes::NamedFunction.new('unaccent', [parent.table[:nom]]) }

  def avec_les_parents_supprimes
    self.class.reflect_on_all_associations(:belongs_to).each do |liaison|
      next if public_send(liaison.name)

      association(liaison.name).target = PaperTrail::Version.where(item_type: liaison.klass.name, item_id: self[liaison.foreign_key]).last&.reify
    end
    self
  end

  def self.ransackable_attributes(_auth_object = nil) = []
  def self.ransackable_associations(_auth_object = nil) = []

  private

  def tirer_le_slug_du_nom
    @slug_tire = self.slug = slug_tire_du_nom
  end

  def oublier_le_slug_tire_si_refus
    self.slug = nil if @slug_tire && errors.any?
    @slug_tire = nil
  end

  def slug_tire_du_nom
    base = self.class.slug_du_nom(nom)
    return if base.empty?

    candidats = (1..).lazy.map { |rang| rang == 1 ? base : "#{base}-#{rang}" }
    candidats.find { !self.class.where(slug: it).where.not(id:).exists? }
  end
end
