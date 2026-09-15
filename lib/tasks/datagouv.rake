namespace :datagouv do
  desc 'Recopie les métadonnées data.gouv des solutions référencées (rejouable)'
  task import: :environment do
    solutions = Solution.sur_datagouv.to_a
    notes = solutions.filter_map(&:rafraichir_datagouv!)
    notes.each { |note| puts "note : #{note}" }
    puts "Import data.gouv terminé — #{solutions.size - notes.size} solution(s) rafraîchie(s) sur #{solutions.size}"
  end
end
