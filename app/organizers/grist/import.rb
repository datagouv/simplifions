class Grist::Import < ApplicationOrganizer
  AUTEUR = 'Import Grist'.freeze

  organize Grist::FetchTables, Grist::PersistCatalogue, Grist::AttachImages

  around { |import| PaperTrail.request(whodunnit: AUTEUR) { import.call } }

  before do
    context.report = { quarantine: [], notes: [] }
    context.index = {}
    context.seen = Hash.new { |modeles, modele| modeles[modele] = [] }
  end

  before do
    context.fail!(error: "Import Grist refusé hors d'un poste de développement : il effacerait les fiches créées dans l'admin") unless Rails.env.local?
  end
end
