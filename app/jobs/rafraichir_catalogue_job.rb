class RafraichirCatalogueJob < ApplicationJob
  limits_concurrency key: 'rafraichir_catalogue', duration: 1.hour, on_conflict: :discard

  def self.dernier_passage = SolidQueue::Job.where(class_name: name).includes(:failed_execution).last

  def perform
    LogStasher.info(event_type: 'rafraichissement_demarre')
    rafraichir
  rescue StandardError => e
    LogStasher.error(event_type: 'rafraichissement_echoue', error_class: e.class.name)
    raise
  end

  private

  def rafraichir
    result = Grist::Import.call
    journaliser(result.report[:quarantine] + result.report[:notes])
    raise result.error if result.failure?

    echecs_datagouv = Solution.rafraichir_datagouv
    journaliser(echecs_datagouv)
    journaliser_fin(result.report, echecs_datagouv)
  end

  def journaliser(notes) = notes.each { |note| Rails.logger.info("Rafraîchissement du catalogue — #{note}") }

  def journaliser_fin(report, echecs_datagouv)
    LogStasher.info(event_type: 'rafraichissement_termine', demarches: Demarche.count, solutions: Solution.count,
      quarantaine: report[:quarantine].size, notes: report[:notes].size,
      datagouv_en_echec: echecs_datagouv.size)
  end
end
