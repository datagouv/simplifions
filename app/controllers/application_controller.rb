class ApplicationController < ActionController::Base
  FACETTES_CATALOGUE = %w[fournisseurs-de-service target-users categorie-de-solution
                          types-de-simplification].freeze
  FILTRES_CATALOGUE = [:q, :sort, *FACETTES_CATALOGUE].freeze
  GUIDE_DES_COMMUNES = 'guide-base-petites-collectivites'.freeze

  private

  def paginer(liste, par_page)
    page = liste.page(params[:page].to_s).per(par_page)
    page.out_of_range? ? liste.page(page.total_pages).per(par_page) : page
  end

  def filtres_catalogue
    params.permit(*FILTRES_CATALOGUE).tap do |filtres|
      FACETTES_CATALOGUE.each do |facette|
        filtres[facette] = filtres[facette].split(',').map { it.delete_prefix("simplifions-v2-#{facette}-") }.join(',') if filtres[facette]
      end
    end
  end

  def guide_du_catalogue
    Article.find(GUIDE_DES_COMMUNES) if @filtres['fournisseurs-de-service'].to_s.split(',').include?('communes') && @catalogue.first_page?
  end
  stale_when_importmap_changes
end
