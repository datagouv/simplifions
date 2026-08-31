class NormaliserLesUrlsDesSolutions < ActiveRecord::Migration[8.1]
  # normalizes ne touche que les écritures : les lignes importées avant ce déploiement
  # gardent leurs URLs brutes jusqu'au prochain import Grist. On comble la fenêtre ici.
  def up
    execute <<~SQL
      UPDATE solutions SET site_internet = trim(site_internet), url_demande_acces = trim(url_demande_acces);
      UPDATE solutions SET site_internet = NULL WHERE site_internet !~* '^https?://';
      UPDATE solutions SET url_demande_acces = NULL WHERE url_demande_acces !~* '^https?://';
    SQL
  end

  def down; end
end
