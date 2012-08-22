# Note : this causes annoying psych warnings under Ruby 1.9.2-p180; to fix, upgrade to 1.9.3
begin
  require 'bundler'
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

using_dsl = false
begin
  require 'rake/dsl_definition'
  using_dsl = true
rescue Exception => e
  # We might just be on an old version of Rake...
end
require 'rake'
if(using_dsl)
  include Rake::DSL
end

require "./lib/annotate"

# want other tests/tasks run by default? Add them to the list
task :default => [:spec]

require 'mg'
MG.new("annotate.gemspec")

require "rspec/core/rake_task" # RSpec 2.0
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = ['spec/*_spec.rb', 'spec/**/*_spec.rb']
  t.rspec_opts = ['--backtrace', '--format d']
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  # t.files   = ['features/**/*.feature', 'features/**/*.rb', 'lib/**/*.rb']
  # t.options = ['--any', '--extra', '--opts'] # optional
end

namespace :yard do
  task :clobber do
    FileUtils.rm_f(".yardoc")
    FileUtils.rm_f("doc")
  end
end
task :clobber => :'yard:clobber'

namespace :rubinius do
  task :clobber do
    FileList["**/*.rbc"].each { |fname| FileUtils.rm_f(fname) }
    FileList[".rbx/**/*"].each { |fname| FileUtils.rm_f(fname) }
  end
end
task :clobber => :'rubinius:clobber'
