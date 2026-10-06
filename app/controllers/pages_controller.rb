class PagesController < ApplicationController
  BESOINS_DE_CONTACT = %w[contenu nouveau-cas-usage modifier-cas-usage nouvelle-solution modifier-solution nouvel-article
                          modifier-article autre-contenu demarche-personnelle question-api probleme-site autre].freeze

  def home; end
  def about; end
  def doctrine_cas_usages; end
  def doctrine_solutions; end
  def niveaux_simplification; end
  def terms; end
  def accessibility; end

  def contact
    @besoin = BESOINS_DE_CONTACT.find { |besoin| besoin == params[:besoin] }
    raise ActionController::RoutingError, 'Not Found' if params[:besoin] && !@besoin
  end

  def sitemap
    @demarches = Demarche.visibles
    @solutions = Solution.visibles.fiches
  end
end
