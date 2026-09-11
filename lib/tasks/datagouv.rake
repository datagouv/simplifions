namespace :datagouv do
  desc 'Recopie les métadonnées data.gouv des solutions référencées (rejouable)'
  task import: :environment do
    solutions = Solution.sur_datagouv
    notes = solutions.find_each.filter_map(&:rafraichir_datagouv!)
    notes.each { |note| puts "note : #{note}" }
    puts "Import data.gouv terminé — #{solutions.count - notes.size} solution(s) rafraîchie(s) sur #{solutions.count}"
  end
end
