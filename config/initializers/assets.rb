# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Modalités d'utilisation du DSFR, réservé aux sites de l'État : https://github.com/GouvernementFR/dsfr/blob/v1.15.4/doc/legal/cgu.md
Dsfr::Assets.accepted_license_version = "1.0.1"
