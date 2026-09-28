# Comptes locaux de l'administration : mot de passe seulement, aucun mail envoyé.
# Seuls les écarts aux défauts de Devise figurent ici.
Devise.setup do |config|
  require "devise/orm/active_record"

  config.stretches = 1 if Rails.env.test?

  # Statuts attendus par Turbo, comme les génère Devise pour une application neuve.
  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other
end
