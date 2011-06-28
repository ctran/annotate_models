require 'rubygems'
require 'rake'
require './lib/annotate'

# want other tests/tasks run by default? Add them to the list
task :default => [:spec]

begin
  require 'mg'
rescue LoadError
  abort "Please `gem install mg`"
end

# mg ("minimalist gems") defines rake tasks:
#
# rake gem
#   Build gem into dist/
# 
# rake gem:publish
#   Push the gem to RubyGems.org
# 
# rake gem:install
#   Build and install as local gem
# 
# rake package
#   Build gem and tarball into dist/
 
MG.new("annotate_models.gemspec")

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "annotate #{Annotate.version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
