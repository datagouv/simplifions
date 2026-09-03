class PagesController < ApplicationController
  def home; end
  def about; end
  def doctrine_cas_usages; end
  def doctrine_solutions; end
  def niveaux_simplification; end
  def terms; end
  def accessibility; end

  def sitemap
    @demarches = Demarche.visibles
    @solutions = Solution.visibles.fiches
  end
end
