class Grist::FetchTables < Grist::ImportStep
  TABLES = %w[
    Cas_d_usages Solutions APIs_et_datasets Operateurs Fournisseurs_de_services Usagers
    Types_de_simplification Categories_de_solution Recommandations API_et_datasets_fournis
    API_et_datasets_integres API_et_datasets_utiles
  ].freeze

  TRIEES = { 'Recommandations' => 'manualSort' }.freeze

  def self.chemin(table)
    "tables/#{table}/records#{"?sort=#{TRIEES[table]}" if TRIEES[table]}"
  end

  def self.url(table) = "#{DOC_URL}/#{chemin(table)}"

  def call
    context.tables = TABLES.index_with { |table| fetch_records(table) }
  end

  private

  def fetch_records(table)
    response = grist_get(self.class.chemin(table))
    context.fail!(error: "Grist #{table}: HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

    records(table, response.body)
  rescue *NETWORK_ERRORS, JSON::ParserError, KeyError => e
    context.fail!(error: "Grist #{table}: #{e.class} — #{e.message}")
  end

  def records(table, body)
    records = JSON.parse(body).fetch('records')
    context.fail!(error: "Grist #{table}: table vide, import interrompu par sécurité") if records.empty?

    records
  end
end
