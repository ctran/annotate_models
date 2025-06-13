if ENV['COVERAGE']
  require 'coveralls'
  require 'codeclimate-test-reporter'
  require 'simplecov'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      Coveralls::SimpleCov::Formatter,
      SimpleCov::Formatter::HTMLFormatter,
      CodeClimate::TestReporter::Formatter
    ]
  )

  SimpleCov.start
end

require 'rubygems'
require 'bundler'
Bundler.setup

require 'rake'
require 'rspec'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'logger'
require 'active_support'

# Ruby 3 removes File.exists? in favor of File.exist?
unless File.respond_to?(:exists?)
  class << File
    alias exists? exist?
  end
end

def capture_stderr
  old = $stderr
  $stderr = StringIO.new
  yield
  $stderr.string
ensure
  $stderr = old
end
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/string/inflections'
require 'annotate'
require 'annotate/parser'
require 'annotate/helpers'
require 'annotate/constants'
require 'byebug'

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run_when_matching :focus
end
