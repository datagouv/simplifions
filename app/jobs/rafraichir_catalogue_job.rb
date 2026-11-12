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
    echecs_datagouv = Solution.rafraichir_datagouv
    echecs_datagouv.each { |note| Rails.logger.info("Rafraîchissement du catalogue — #{note}") }
    LogStasher.info(event_type: 'rafraichissement_termine', demarches: Demarche.count, solutions: Solution.count,
      datagouv_en_echec: echecs_datagouv.size)
  end
end
