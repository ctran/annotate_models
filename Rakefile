here = File.dirname __FILE__

# Note : this causes annoying psych warnings under Ruby 1.9.2-p180; to fix, upgrade to 1.9.3
begin
  require 'bundler'
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake/dsl_definition'
require 'rake'
include Rake::DSL

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
MG.new("annotate.gemspec")

task :default => :spec

require "rspec/core/rake_task" # RSpec 2.0
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = ['spec/*_spec.rb', 'spec/**/*_spec.rb']
end

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "annotated_models #{Annotate.version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
