require 'rubygems'
require 'rake'
require 'lib/annotate'

# want other tests/tasks run by default? Add them to the list
task :default => [:spec]

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "annotate"
    gem.executables = "annotate"
    gem.summary = "Annotates Rails Models, routes, fixtures, and others based on the database schema."
    gem.description = gem.summary
    gem.email = ["alex@stinky.com", 'ctran@pragmaquest.com', "x@nofxx.com"]
    gem.homepage = "http://github.com/ctran/annotate"
    gem.authors = ['Cuong Tran', "Alex Chaffee", "Marcos Piccinini"]
    gem.files =  FileList["[A-Z]*.*", "{bin,lib,tasks,spec}/**/*"]
    gem.rubyforge_project = "annotate"
    
    # note that Jeweler automatically reads the version from VERSION.yml
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
  
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "annotate #{Annotate.version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
