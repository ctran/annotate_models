begin
  require 'rspec'
rescue LoadError
  require 'rubygems'
  gem 'rspec-core'
  require 'rspec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'annotate'
