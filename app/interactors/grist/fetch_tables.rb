class Grist::FetchTables < Grist::ImportStep
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
    response = grist_get("tables/#{table}/records")
    context.fail!(error: "Grist #{table}: HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

    records = JSON.parse(response.body).fetch('records')
    context.fail!(error: "Grist #{table}: table vide, import interrompu par sécurité") if records.empty?

    records
  rescue *NETWORK_ERRORS => e
    context.fail!(error: "Grist #{table}: #{e.class} — #{e.message}")
  end
end
