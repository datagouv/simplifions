class ApplicationController < ActionController::Base
  # Mêmes paramètres que les listes du site actuel ; tout le reste (tableaux, hashes, options de route) est ignoré.
  FILTRES_CATALOGUE = [:q, :sort, :page, 'fournisseurs-de-service', 'target-users', 'categorie-de-solution',
                       'types-de-simplification'].freeze

  private

  def filtres_catalogue = params.permit(*FILTRES_CATALOGUE)
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
