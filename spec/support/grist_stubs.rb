module GristStubs
  def stub_grist_tables
    Grist::FetchTables::TABLES.each do |table|
      stub_request(:get, "#{Grist::FetchTables::DOC_URL}/tables/#{table}/records")
        .to_return(status: 200, body: Rails.root.join("spec/fixtures/grist/#{table}.json").read,
          headers: { 'Content-Type' => 'application/json' })
    end
  end
end

RSpec.configure { |config| config.include GristStubs }
