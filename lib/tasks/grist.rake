namespace :grist do
  desc 'Importe le catalogue depuis Grist (rejouable, idempotent)'
  task import: :environment do
    result = Grist::Import.call

    result.report[:quarantine].each { |line| puts "quarantaine : #{line}" }
    result.report[:notes].each { |line| puts "note : #{line}" }

    if result.success?
      puts "Import Grist terminé — #{Demarche.count} démarches, #{Solution.count} solutions, " \
           "#{Integration.count} intégrations, #{Recommandation.count} recommandations"
    else
      puts "Import Grist échoué : #{result.error}"
      exit 1
    end
  end
end
