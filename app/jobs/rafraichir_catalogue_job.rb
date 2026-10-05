class RafraichirCatalogueJob < ApplicationJob
  limits_concurrency key: 'rafraichir_catalogue', duration: 1.hour, on_conflict: :discard

  def perform
    result = Grist::Import.call
    journaliser(result.report[:quarantine] + result.report[:notes])
    raise result.error if result.failure?

    journaliser(Solution.sur_datagouv.filter_map(&:rafraichir_datagouv!))
  end

  private

  def journaliser(notes) = notes.each { |note| Rails.logger.info("Rafraîchissement du catalogue — #{note}") }
end
