class ApplicationController < ActionController::Base
  # Mêmes paramètres que les listes du site actuel ; tout le reste (tableaux, hashes, options de route) est ignoré.
  FACETTES_CATALOGUE = %w[fournisseurs-de-service target-users categorie-de-solution
                          types-de-simplification].freeze
  FILTRES_CATALOGUE = [:q, :sort, :page, *FACETTES_CATALOGUE].freeze

  private

  # Le site actuel publie les facettes sous leur forme tag (`simplifions-v2-target-users-particuliers`) :
  # ces liens doivent continuer à filtrer.
  def filtres_catalogue
    params.permit(*FILTRES_CATALOGUE).tap do |filtres|
      FACETTES_CATALOGUE.each do |facette|
        filtres[facette] = filtres[facette].delete_prefix("simplifions-v2-#{facette}-") if filtres[facette]
      end
    end
  end
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
