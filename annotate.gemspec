# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'annotate/version'

Gem::Specification.new do |spec|
  spec.name = 'annotate'
  spec.version = Annotate::VERSION
  spec.authors = ['Alex Chaffee', 'Cuong Tran', 'Marcos Piccinini', 'Turadg Aleahmad', 'Jon Frisby']
  spec.email = [
    'alex@stinky.com', 'cuong.tran@gmail.com', 'x@nofxx.com',
    'turadg@aleahmad.net', 'jon@cloudability.com'
  ]

  spec.summary = 'Annotates Rails models, routes, fixtures, and other files based on the database schema.'
  spec.description = 'Annotates Rails models, routes, fixtures, and other files based on the database schema.'
  spec.homepage = 'http://github.com/ctran/annotate_models'
  spec.license = 'Ruby'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  spec.bindir = 'bin'
  spec.executables = ['annotate']
  spec.require_paths = ['lib']

  spec.extra_rdoc_files = ['README.rdoc', 'CHANGELOG.rdoc', 'TODO.rdoc']

  spec.add_runtime_dependency(%q<rake>, ['>= 10.4'])
  spec.add_runtime_dependency(%q<activerecord>, ['>= 3.2', '< 6.0'])
end
