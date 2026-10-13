namespace :datagouv do
  desc 'Recopie les métadonnées data.gouv des solutions référencées (rejouable)'
  task import: :environment do
    total = Solution.sur_datagouv.count
    notes = Solution.rafraichir_datagouv
    notes.each { |note| puts "note : #{note}" }
    puts "Import data.gouv terminé — #{total - notes.size} solution(s) rafraîchie(s) sur #{total}"
  end
end
