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

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'mg'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'terminal-notifier-guard'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'overcommit'
  spec.add_development_dependency 'ruby_dep', '1.3.1'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-coolline'

  spec.add_development_dependency 'files'
  spec.add_development_dependency 'wrong'

  spec.add_runtime_dependency(%q<rake>, ['>= 10.4'])
  spec.add_runtime_dependency(%q<activerecord>, ['>= 3.2', '< 6.0'])
end
