require 'coveralls'
Coveralls.wear!
require 'timecop'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'banjaxer'

RSpec.configure do |config|
  config.order = 'random'

#  # Use tmp/ to write files
#  $pwd = FileUtils.pwd
#  config.before(:each) do
#    FileUtils.rm_rf 'tmp'
#    FileUtils.mkdir_p 'tmp'
#    FileUtils.cd 'tmp'
#  end
#
#  config.after(:each) do
#    FileUtils.cd $pwd
#  end

  # Suppress CLI output. This *will* fuck with Pry
  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:all) do
    # Redirect stderr and stdout
    $stderr = File.new '/dev/null', 'w'
    $stdout = File.new '/dev/null', 'w'
  end

  config.after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

require_relative 'support/vcr_setup'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
