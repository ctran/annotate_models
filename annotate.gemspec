# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'annotate/version'

Gem::Specification.new do |s|
  s.name = 'annotate'
  s.version = Annotate.version

  s.required_ruby_version = '>= 2.4.0'
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Alex Chaffee', 'Cuong Tran', 'Marcos Piccinini', 'Turadg Aleahmad', 'Jon Frisby']
  s.description = 'Annotates Rails/ActiveRecord Models, routes, fixtures, and others based on the database schema.'
  s.email = ['alex@stinky.com', 'cuong.tran@gmail.com', 'x@nofxx.com', 'turadg@aleahmad.net', 'jon@cloudability.com']
  s.executables = ['annotate']
  s.extra_rdoc_files = ['README.md', 'CHANGELOG.md']
  s.files = `git ls-files -z LICENSE.txt *.md *.gemspec bin lib`.split("\x0")
  s.homepage = 'http://github.com/ctran/annotate_models'
  s.licenses = ['Ruby']
  s.require_paths = ['lib']
  s.rubygems_version = '2.1.11'
  s.summary = 'Annotates Rails Models, routes, fixtures, and others based on the database schema.'

  s.specification_version = 4 if s.respond_to? :specification_version
  s.add_runtime_dependency(%q<rake>, '>= 10.4', '< 14.0')
  s.add_runtime_dependency(%q<activerecord>, ['>= 3.2', '< 7.0'])

  s.metadata = { "github_repo" => "ssh://github.com/ctran/annotate_models" }
end
