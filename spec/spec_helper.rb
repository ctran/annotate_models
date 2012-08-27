require 'rubygems'
require 'bundler'
Bundler.setup

require 'rspec'
require 'wrong/adapters/rspec'

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift(File.dirname(__FILE__))

require 'active_support'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/string/inflections'
require 'annotate'

module Annotate
  module Integration
    ABSOLUTE_GEM_ROOT=File.expand_path('../../', __FILE__)

    CRUFT_PATTERNS=[
      "%SCENARIO%/bin/*", "%SCENARIO%/log/*", "%SCENARIO%/tmp/*",
      "%SCENARIO%/.bundle"
    ]
    SCENARIO_HOME=File.join(File.dirname(__FILE__), 'integration')
    SCENARIOS=Dir.glob("#{SCENARIO_HOME}/*").
      select { |candidate| File.directory?(candidate) }.
      map do |test_rig|
        base_dir = File.basename(test_rig)
        [test_rig, base_dir, base_dir.titlecase]
      end

    def self.nuke_cruft(test_rig)
      FileList[
        Annotate::Integration::CRUFT_PATTERNS.
          map { |pattern| pattern.sub('%SCENARIO%', test_rig) }
      ].each do |fname|
        FileUtils.rm_rf(fname)
      end
    end

    def self.nuke_all_cruft
      SCENARIOS.each do |test_rig, base_dir, test_name|
        nuke_cruft(test_rig)
      end
    end

    def self.empty_gemset(test_rig)
      Dir.chdir(test_rig) do
        system(%q{
          (
            export SKIP_BUNDLER=1
            source .rvmrc &&
            rvm --force gemset empty
          ) 2>&1
        })
      end
    end

    def self.reset_dirty_files
      system("git checkout HEAD -- #{SCENARIO_HOME}/*/")
    end

    def self.clear_untracked_files
      system("git clean -dfx #{SCENARIO_HOME}/*/")
    end

    def self.is_clean?(test_rig)
      return `git status --porcelain #{test_rig}/ | wc -l`.strip.to_i == 0
    end
  end
end
