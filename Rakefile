require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake/dsl_definition'
require 'rake'

# want other tests/tasks run by default? Add them to the list
task :default => [:spec]

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "annotate"
  gem.summary = "Annotates Rails models, routes, fixtures, and others based on the database schema."
  gem.description = "When run, inserts table descriptions from db.schema into a comment block of relevant source code."
  gem.email = ['ctran@pragmaquest.com', "alex@stinky.com", "x@nofxx.com", "turadg@aleahmad.net"]
  gem.homepage = "http://github.com/MrJoy/annotate_models"
  gem.authors = ['Cuong Tran', "Alex Chaffee", "Marcos Piccinini", "Turadg Aleahmad"]

  gem.rubyforge_project = "annotate"

  gem.test_files =  `git ls-files -- {spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_path = 'lib'

  # note that Jeweler automatically reads the version from VERSION.yml
  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
end

Jeweler::GemcutterTasks.new


require "rspec/core/rake_task" # RSpec 2.0
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = ['spec/*_spec.rb', 'spec/**/*_spec.rb']
end

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "annotated_models #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
