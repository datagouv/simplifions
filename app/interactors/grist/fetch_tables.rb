require 'net/http'

class Grist::FetchTables < ApplicationInteractor
  DOC_URL = 'https://grist.numerique.gouv.fr/api/docs/ofSVjCSAnMb6'.freeze
  TABLES = %w[
    Cas_d_usages Solutions APIs_et_datasets Operateurs Fournisseurs_de_services Usagers
    Types_de_simplification Categories_de_solution Recommandations API_et_datasets_fournis
    API_et_datasets_integres API_et_datasets_utiles
  ].freeze

  def call
    context.tables = TABLES.index_with { |table| fetch_records(table) }
  end

  private

  def fetch_records(table)
    response = Net::HTTP.get_response(URI("#{DOC_URL}/tables/#{table}/records"))
    fail_with!("Grist #{table}: HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch('records')
  end
end
