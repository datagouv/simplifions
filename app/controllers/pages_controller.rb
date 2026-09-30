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
    @fiche = fiche_concernee
  end

  def sitemap
    @demarches = Demarche.visibles
    @solutions = Solution.visibles.fiches
  end

  private

  # Seul un slug de fiche publiée est accepté : aucun texte libre de l'URL n'arrive dans le mail.
  def fiche_concernee
    fiches = { 'demarche' => Demarche.visibles, 'solution' => Solution.visibles.fiches }[@besoin&.fiche]
    fiche = fiches&.find_by(slug: params.fetch(:page, nil).presence)
    BesoinContact::Fiche.new(fiche.nom, public_send("#{@besoin.fiche}_url", fiche.slug)) if fiche
  end
end
