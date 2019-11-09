require 'coveralls'
require 'codeclimate-test-reporter'
require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    Coveralls::SimpleCov::Formatter,
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter
  ]
)

SimpleCov.start

require 'rubygems'
require 'bundler'
Bundler.setup

require 'rake'
require 'rspec'
require 'wrong/adapters/rspec'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/string/inflections'
require 'annotate'
require 'annotate/parser'
require 'byebug'

module Annotate
  module Integration
    ABSOLUTE_GEM_ROOT = File.expand_path('../../', __FILE__)

    CRUFT_PATTERNS = %w(
      %SCENARIO%/bin/*
      %SCENARIO%/log/*
      %SCENARIO%/tmp/*
      %SCENARIO%/.bundle
    ).freeze

    SCENARIO_HOME = File.join(File.dirname(__FILE__), 'integration')
    SCENARIOS = Dir.glob("#{SCENARIO_HOME}/*").select do |candidate|
      File.directory?(candidate)
    end.map do |test_rig|
      base_dir = File.basename(test_rig)
      [test_rig, base_dir, base_dir.titlecase]
    end

    def self.nuke_cruft(test_rig)
      FileList[
        Annotate::Integration::CRUFT_PATTERNS.map do |pattern|
          pattern.sub('%SCENARIO%', test_rig)
        end
      ].each do |fname|
        FileUtils.rm_rf(fname)
      end
    end

    def self.nuke_all_cruft
      SCENARIOS.each do |test_rig, _base_dir, _test_name|
        nuke_cruft(test_rig)
      end
    end

    def self.empty_gemset(test_rig)
      Dir.chdir(test_rig) do
        system('
          (
            export SKIP_BUNDLER=1
            source .rvmrc &&
            rvm --force gemset empty
          ) 2>&1
        ')
      end
    end

    def self.reset_dirty_files
      system("git checkout HEAD -- #{SCENARIO_HOME}/*/")
    end

    def self.clear_untracked_files
      system("git clean -dfx #{SCENARIO_HOME}/*/")
    end

    def self.clean?(test_rig)
      `git status --porcelain #{test_rig}/ | wc -l`.strip.to_i.zero?
    end
  end
end
