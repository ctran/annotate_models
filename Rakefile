require 'rubygems'
require 'rake/dsl_definition'
require 'rake'

# want other tests/tasks run by default? Add them to the list
task :default => [:spec]

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "annotate_models"
  gem.summary = "Annotates Rails models, routes, fixtures, and others based on the database schema."
  gem.description = "When run, inserts table descriptions from db.schema into a comment block of relevant source code."
  gem.email = ["alex@stinky.com", 'ctran@pragmaquest.com', "x@nofxx.com", "turadg@aleahmad.net"]
  gem.homepage = "http://github.com/ctran/annotate_models"
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

# FIXME warns "already initialized constant Task"
# FIXME throws "uninitialized constant RDoc::VISIBILITIES"
# require 'rdoc/task'
# RDoc::Task.new do |rdoc|
#   rdoc.main = "README.rdoc"
#   rdoc.rdoc_files.include("README.rdoc", "lib/**/*.rb")
#   # require 'lib/annotate'
#   # rdoc.title = "annotate #{Annotate.version}"
# end
