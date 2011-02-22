require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "annotated_models"
  gem.homepage = "http://github.com/openteam/annotated_models"
  gem.license = "MIT"
  gem.summary = %Q{Annotate ActiveRecord models as a gem}
  gem.description = %Q{Add a comment summarizing the current schema to the top or bottom of each of your models}
  gem.email = "lda@openteam.ru"
  gem.authors = ["Dave Thomas", "Alex Chaffee", "Cuong Tran", "Alex Chaffee", "Dmitry Lihachev"]

  gem.add_development_dependency(%q<bundler>, [">= 0"])
  gem.add_development_dependency(%q<jeweler>, [">= 0"])
  gem.add_development_dependency(%q<rcov>, [">= 0"])
  gem.add_development_dependency(%q<fakefs>, [">= 0"])
  gem.add_development_dependency(%q<rspec>, [">= 0"])

  gem.add_runtime_dependency(%q<activesupport>, [">= 0"])
  gem.add_runtime_dependency(%q<i18n>, [">= 0"])
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "annotated_models #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
