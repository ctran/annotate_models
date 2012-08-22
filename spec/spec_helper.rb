require 'rubygems'
require 'bundler'
Bundler.setup

require 'rspec'
require 'wrong/adapters/rspec'

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift(File.dirname(__FILE__))

require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'annotate'
