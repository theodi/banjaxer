require 'coveralls'
Coveralls.wear!
require 'vcr'
require 'timecop'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'banjaxer'

RSpec.configure do |config|
  config.order = 'random'
end

RSpec::Matchers.define :exit_with_status do |expected|
  match do |actual|
    begin
      actual.call
    rescue SystemExit => e
      expect(e.status).to eq expected
    end
  end

  supports_block_expectations
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :once }
  c.allow_http_connections_when_no_cassette = false
  c.configure_rspec_metadata!
end
