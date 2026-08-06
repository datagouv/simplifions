class ArticlesController < ApplicationController
  def index
    @selected_keywords = params[:keywords].to_s.split(',')
    @articles = Article.filtered(@selected_keywords)
  end

  def show
    @article = Article.find(params.expect(:slug)) or raise ActionController::RoutingError, 'article inconnu'
    render @article.template
  end
end
