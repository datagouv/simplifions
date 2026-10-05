require 'rails_helper'
require Rails.root.join('db/migrate/20261005150000_dater_les_fiches_creees_dans_l_admin.rb')

RSpec.describe DaterLesFichesCreeesDansLAdmin do
  let(:creation) { Time.zone.local(2026, 9, 1, 10) }

  [Demarche, Solution].each do |modele|
    it "date de leur création les fiches #{modele.table_name} saisies dans l'admin, pas celles du Grist" do
      saisie = modele.create!(nom: 'Saisie admin', created_at: creation)
      importee = modele.create!(nom: 'Importée', grist_id: 'rec1', created_at: creation)

      ActiveRecord::Migration.suppress_messages { described_class.new.up }

      expect([saisie.reload.cree_le, importee.reload.cree_le]).to eq([creation, nil])
    end
  end
end
