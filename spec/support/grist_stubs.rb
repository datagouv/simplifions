module GristStubs
  def stub_grist_tables
    Grist::FetchTables::TABLES.each do |table|
      stub_request(:get, Grist::FetchTables.url(table))
        .to_return(status: 200, body: Rails.root.join("spec/fixtures/grist/#{table}.json").read,
          headers: { 'Content-Type' => 'application/json' })
    end
  end
end

RSpec.configure { |config| config.include GristStubs }
