# Comptes locaux de l'administration : mot de passe seulement, aucun mail envoyé.
Devise.setup do |config|
  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.sign_out_via = :delete

  # Statuts attendus par Turbo, comme les génère Devise pour une application neuve.
  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other
end
