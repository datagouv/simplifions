class PagesController < ApplicationController
  BESOINS_DE_CONTACT = %w[contenu nouveau-cas-usage modifier-cas-usage nouvelle-solution modifier-solution nouvel-article
                          modifier-article autre-contenu demarche-personnelle question-api probleme-site autre
                          donner-son-avis].freeze

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

    @fiche = fiche_d_origine
    @demarches = Demarche.visibles.order(:nom) if @besoin == 'modifier-cas-usage'
    @solutions = Solution.visibles.fiches.includes(:organisations).order(:nom) if @besoin == 'modifier-solution'
  end

  def sitemap
    @demarches = Demarche.visibles.order(:nom)
    @solutions = Solution.visibles.fiches.order(:nom)
    @articles = Article.all.sort_by(&:h1)
  end

  private

  def fiche_d_origine
    case @besoin
    when 'modifier-cas-usage' then fiche_publiee(Demarche.visibles, params[:demarche])
    when 'modifier-solution' then fiche_publiee(Solution.visibles.fiches, params[:solution])
    when 'donner-son-avis' then page_de_l_avis
    end
  end

  def page_de_l_avis
    fiche_publiee(Demarche.visibles, params[:demarche]) ||
      fiche_publiee(Solution.visibles.fiches, params[:solution]) ||
      article_publie(params[:article])
  end

  def article_publie(slug)
    Article.find(slug) if slug.is_a?(String)
  end

  def fiche_publiee(fiches, slug)
    fiches.find_by(slug:) if slug.is_a?(String)
  end
end
