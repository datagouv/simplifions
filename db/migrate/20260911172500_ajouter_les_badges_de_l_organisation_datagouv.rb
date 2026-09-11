class AjouterLesBadgesDeLOrganisationDatagouv < ActiveRecord::Migration[8.1]
  def change
    add_column :solutions, :datagouv_organisation_badges, :string, array: true, default: [], null: false
  end
end
