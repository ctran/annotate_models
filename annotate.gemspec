here = File.dirname __FILE__
require "#{here}/lib/annotate"

Gem::Specification.new do |s|
  s.name = %q{annotate}
  s.version = Annotate.version
  s.description = %q{Annotates Rails/ActiveRecord Models, routes, fixtures, and others based on the database schema.}
  s.summary = %q{Annotates Rails Models, routes, fixtures, and others based on the database schema.}
  s.authors = ["Cuong Tran", "Alex Chaffee", "Marcos Piccinini", "Turadg Aleahmad"]
  s.email = ["alex@stinky.com", "ctran@pragmaquest.com", "x@nofxx.com", "turadg@aleahmad.net"]

  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = ["README.rdoc"]
  
  s.files             = %w( README.rdoc VERSION.yml History.txt )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("tasks/**/*")  
  s.files            += ["bin/annotate"]  # todo: annotate_models

  s.homepage = %q{http://github.com/ctran/annotate_models}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{annotate}

  s.add_runtime_dependency 'rake'  # ?
end

