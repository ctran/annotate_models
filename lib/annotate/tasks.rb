require 'rubygems'
require 'rake'

# Make tasks visible for Rails also when used as gem.
Dir[File.join(File.dirname(__FILE__), '..', 'tasks', '**/*.rake')].each { |rake| load rake }
Dir[File.join(File.dirname(__FILE__), '..', '..', 'tasks', '**/*.rake')].each { |rake| load rake }
