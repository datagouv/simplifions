class PagesController < ApplicationController
  def home; end
  def about; end
  def doctrine_cas_usages; end
  def doctrine_solutions; end
  def niveaux_simplification; end
  def terms; end
  def accessibility; end

  # Fiches depuis lesquelles on peut arriver sur /contact, passées en `?demarche=<slug>` ou `?solution=<slug>`.
  FICHES_ORIGINE = { demarche: -> { Demarche.visibles }, solution: -> { Solution.visibles.fiches } }.freeze

  def contact
    @besoin = BesoinContact.find(params.fetch(:besoin, nil))
    # Seul un texte est lu : un tableau ou un hash (`demarche[x]=1`) est ignoré.
    @origine = FICHES_ORIGINE.keys.index_with { |type| params[type] }
      .select { |_type, slug| slug.is_a?(String) && slug.present? }
    @fiche = fiche_concernee
  end

  def sitemap
    @demarches = Demarche.visibles
    @solutions = Solution.visibles.fiches
  end

  private

  # Seul un slug de fiche publiée, du type attendu par l'étape, est accepté :
  # aucun texte libre de l'URL n'arrive dans le mail.
  def fiche_concernee
    type = @besoin&.fiche&.to_sym
    slug = @origine[type]
    fiche = FICHES_ORIGINE.fetch(type).call.find_by(slug:) if slug
    BesoinContact::Fiche.new(fiche.nom, public_send("#{type}_url", fiche.slug)) if fiche
  end
end
