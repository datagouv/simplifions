RSpec.shared_context 'with a captured LogStasher log' do
  let(:logstash_io) { StringIO.new }

  around do |example|
    previous = [LogStasher.logger, LogStasher.field_renaming]
    LogStasher.logger = Logger.new(logstash_io)
    LogStasher.field_renaming = {}
    example.run
  ensure
    LogStasher.logger, LogStasher.field_renaming = previous
  end

  def logstash_lines
    logstash_io.string.lines.map { |line| JSON.parse(line) }
  end
end
