$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'annotate/version'
require 'annotate/annotate_models'
require 'annotate/annotate_routes'
require 'annotate/constants'
require 'annotate/helpers'

begin
  # ActiveSupport 3.x...
  require 'active_support/hash_with_indifferent_access'
  require 'active_support/core_ext/object/blank'
rescue StandardError
  # ActiveSupport 2.x...
  require 'active_support/core_ext/hash/indifferent_access'
  require 'active_support/core_ext/blank'
end

module Annotate
  ##
  # Set default values that can be overridden via environment variables.
  #
  def self.set_defaults(options = {})
    return if @has_set_defaults
    @has_set_defaults = true

    options = ActiveSupport::HashWithIndifferentAccess.new(options)

    Constants::ALL_ANNOTATE_OPTIONS.flatten.each do |key|
      if options.key?(key)
        default_value = if options[key].is_a?(Array)
                          options[key].join(',')
                        else
                          options[key]
                        end
      end

      default_value = ENV[key.to_s] unless ENV[key.to_s].blank?
      ENV[key.to_s] = default_value.nil? ? nil : default_value.to_s
    end
  end

  ##
  # TODO: what is the difference between this and set_defaults?
  #
  def self.setup_options(options = {})
    Constants::POSITION_OPTIONS.each do |key|
      options[key] = Annotate::Helpers.fallback(ENV[key.to_s], ENV['position'], 'before')
    end
    Constants::FLAG_OPTIONS.each do |key|
      options[key] = Annotate::Helpers.true?(ENV[key.to_s])
    end
    Constants::OTHER_OPTIONS.each do |key|
      options[key] = !ENV[key.to_s].blank? ? ENV[key.to_s] : nil
    end
    Constants::PATH_OPTIONS.each do |key|
      options[key] = !ENV[key.to_s].blank? ? ENV[key.to_s].split(',') : []
    end

    options[:additional_file_patterns] ||= []
    options[:additional_file_patterns] = options[:additional_file_patterns].split(',') if options[:additional_file_patterns].is_a?(String)
    options[:model_dir] = ['app/models'] if options[:model_dir].empty?

    options[:wrapper_open] ||= options[:wrapper]
    options[:wrapper_close] ||= options[:wrapper]

    # These were added in 2.7.0 but so this is to revert to old behavior by default
    options[:exclude_scaffolds] = Annotate::Helpers.true?(ENV.fetch('exclude_scaffolds', 'true'))
    options[:exclude_controllers] = Annotate::Helpers.true?(ENV.fetch('exclude_controllers', 'true'))
    options[:exclude_helpers] = Annotate::Helpers.true?(ENV.fetch('exclude_helpers', 'true'))

    options
  end

  def self.load_tasks
    return if @tasks_loaded

    Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each do |rake|
      load rake
    end

    @tasks_loaded = true
  end

  def self.eager_load(options)
    load_requires(options)
    require 'annotate/active_record_patch'

    if defined?(Rails::Application)
      if Rails.version.split('.').first.to_i < 3
        Rails.configuration.eager_load_paths.each do |load_path|
          matcher = /\A#{Regexp.escape(load_path)}(.*)\.rb\Z/
          Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
            require_dependency file.sub(matcher, '\1')
          end
        end
      else
        klass = Rails::Application.send(:subclasses).first
        klass.eager_load!
      end
    else
      options[:model_dir].each do |dir|
        FileList["#{dir}/**/*.rb"].each do |fname|
          require File.expand_path(fname)
        end
      end
    end
  end

  def self.bootstrap_rake
    begin
      require 'rake/dsl_definition'
    rescue StandardError => e
      # We might just be on an old version of Rake...
      $stderr.puts e.message
      exit e.status_code
    end
    require 'rake'

    load './Rakefile' if File.exist?('./Rakefile')
    begin
      Rake::Task[:environment].invoke
    rescue
      nil
    end
    unless defined?(Rails)
      # Not in a Rails project, so time to load up the parts of
      # ActiveSupport we need.
      require 'active_support'
      require 'active_support/core_ext/class/subclasses'
      require 'active_support/core_ext/string/inflections'
    end

    load_tasks
    Rake::Task[:set_annotation_options].invoke
  end

  class << self
    private

    def load_requires(options)
      options[:require].count > 0 &&
        options[:require].each { |path| require path }
    end
  end
end
