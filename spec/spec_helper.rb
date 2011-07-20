begin
  require 'rspec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'rspec'
end

require "wrong/adapters/rspec"

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'annotate'
