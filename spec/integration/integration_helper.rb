class IntegrationHelper
  MIN_RUBY_VERSIONS = {
    'rails_5.2.4.1' => '>= 2.2.2',
    'rails_6.0.2.1' => '>= 2.5.0'
  }.freeze

  def self.able_to_run?(file_path, ruby_version)
    return false unless ENV['INTEGRATION_TESTS']

    file_name = File.basename(file_path)
    rails_app = File.basename(file_name, '_spec.rb')
    ruby_dependency = MIN_RUBY_VERSIONS[rails_app]

    required_version = Gem::Dependency.new('', ruby_dependency)
    able_to_run = required_version.match?('', ruby_version)

    unless able_to_run
      output = "\n" \
            "Skipping running the integration test for #{file_name}.\n" \
            "The current version of Ruby is #{ruby_version}, " \
            "but the integration test requires Ruby #{ruby_dependency}."
      puts output
    end

    able_to_run
  end
end
