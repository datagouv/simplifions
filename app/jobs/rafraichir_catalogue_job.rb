class RafraichirCatalogueJob < ApplicationJob
  def perform
    result = Grist::Import.call
    journaliser(result.report[:quarantine] + result.report[:notes])
    raise result.error if result.failure?

    journaliser(Solution.sur_datagouv.filter_map(&:rafraichir_datagouv!))
  end

  private

  def journaliser(notes) = notes.each { |note| Rails.logger.info("Rafraîchissement du catalogue — #{note}") }
end
