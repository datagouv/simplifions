class PagesController < ApplicationController
  def home; end
  def about; end
  def doctrine_cas_usages; end
  def doctrine_solutions; end
  def niveaux_simplification; end
  def terms; end
  def accessibility; end

  def contact
    @besoin = BesoinContact.find(params.fetch(:besoin, nil))
    @page = params[:page].presence if params[:page].is_a?(String)
    @fiche = fiche_concernee
  end

  def sitemap
    @demarches = Demarche.visibles
    @solutions = Solution.visibles.fiches
  end

  private

  # `page` n'est lu que sous forme de texte : un tableau ou un hash (`page[x]=1`) est ignoré.
  # Seul un slug de fiche publiée est accepté : aucun texte libre de l'URL n'arrive dans le mail.
  def fiche_concernee
    fiches = { 'demarche' => Demarche.visibles, 'solution' => Solution.visibles.fiches }[@besoin&.fiche]
    fiche = fiches&.find_by(slug: @page)
    BesoinContact::Fiche.new(fiche.nom, public_send("#{@besoin.fiche}_url", fiche.slug)) if fiche
  end
end
