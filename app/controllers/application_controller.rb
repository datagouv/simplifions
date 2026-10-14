class ApplicationController < ActionController::Base
  FACETTES_CATALOGUE = %w[fournisseurs-de-service target-users categorie-de-solution
                          types-de-simplification].freeze
  FILTRES_CATALOGUE = [:q, :sort, *FACETTES_CATALOGUE].freeze

  private

  def paginer(liste, par_page)
    page = liste.page(params[:page].to_s).per(par_page)
    page.out_of_range? ? liste.page(page.total_pages).per(par_page) : page
  end

  def filtres_catalogue
    params.permit(*FILTRES_CATALOGUE).tap do |filtres|
      FACETTES_CATALOGUE.each do |facette|
        filtres[facette] = filtres[facette].delete_prefix("simplifions-v2-#{facette}-") if filtres[facette]
      end
    end
  end
  allow_browser versions: :modern

  stale_when_importmap_changes
end
