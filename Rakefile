here = File.dirname __FILE__

require 'rubygems'
require 'rake'
require "#{here}/lib/annotate"

# want other tests/tasks run by default? Add them to the list
task :default => [:spec]

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
begin
  require 'mg'
rescue LoadError
  abort "Please `gem install mg`"
end
MG.new("annotate_models.gemspec")

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec

require "rspec/core/rake_task" # RSpec 2.0
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = ['spec/*_spec.rb', 'spec/**/*_spec.rb']
end

# FIXME not working yet
RSpec::Core::RakeTask.new(:rcov) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
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
