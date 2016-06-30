$:.unshift(File.dirname(__FILE__))
require 'annotate/version'
require 'annotate/annotate_models'
require 'annotate/annotate_routes'

begin
  # ActiveSupport 3.x...
  require 'active_support/hash_with_indifferent_access'
  require 'active_support/core_ext/object/blank'
rescue Exception
  # ActiveSupport 2.x...
  require 'active_support/core_ext/hash/indifferent_access'
  require 'active_support/core_ext/blank'
end

module Annotate
  ##
  # The set of available options to customize the behavior of Annotate.
  #
  POSITION_OPTIONS=[
    :position_in_routes, :position_in_class, :position_in_test,
    :position_in_fixture, :position_in_factory, :position,
    :position_in_serializer
  ]
  FLAG_OPTIONS=[
    :show_indexes, :simple_indexes, :include_version, :exclude_tests,
    :exclude_fixtures, :exclude_factories, :ignore_model_sub_dir,
    :format_bare, :format_rdoc, :format_markdown, :sort, :force, :trace,
    :timestamp, :exclude_serializers, :classified_sort, :show_foreign_keys,
    :exclude_scaffolds, :exclude_controllers, :exclude_helpers, :ignore_unknown_models,
  ]
  OTHER_OPTIONS=[
    :ignore_columns, :skip_on_db_migrate, :wrapper_open, :wrapper_close, :wrapper, :routes,
    :hide_limit_column_types,
  ]
  PATH_OPTIONS=[
    :require, :model_dir, :root_dir
  ]

  ##
  # Set default values that can be overridden via environment variables.
  #
  def self.set_defaults(options = {})
    return if(@has_set_defaults)
    @has_set_defaults = true

    options = HashWithIndifferentAccess.new(options)

    [POSITION_OPTIONS, FLAG_OPTIONS, PATH_OPTIONS, OTHER_OPTIONS].flatten.each do |key|
      if options.has_key?(key)
        default_value = if options[key].is_a?(Array)
          options[key].join(",")
        else
          options[key]
        end
      end

      default_value = ENV[key.to_s] if !ENV[key.to_s].blank?
      ENV[key.to_s] = default_value.nil? ? nil : default_value.to_s
    end
  end

  TRUE_RE = /^(true|t|yes|y|1)$/i
  def self.setup_options(options = {})
    POSITION_OPTIONS.each do |key|
      options[key] = fallback(ENV[key.to_s], ENV['position'], 'before')
    end
    FLAG_OPTIONS.each do |key|
      options[key] = true?(ENV[key.to_s])
    end
    OTHER_OPTIONS.each do |key|
      options[key] = (!ENV[key.to_s].blank?) ? ENV[key.to_s] : nil
    end
    PATH_OPTIONS.each do |key|
      options[key] = (!ENV[key.to_s].blank?) ? ENV[key.to_s].split(',') : []
    end

    if(options[:model_dir].empty?)
      options[:model_dir] = ['app/models']
    end

    if(options[:root_dir].empty?)
      options[:root_dir] = ['']
    end

    options[:wrapper_open] ||= options[:wrapper]
    options[:wrapper_close] ||= options[:wrapper]

    return options
  end

  def self.reset_options
    [POSITION_OPTIONS, FLAG_OPTIONS, PATH_OPTIONS, OTHER_OPTIONS].flatten.each do |key|
      ENV[key.to_s] = nil
    end
  end

  def self.skip_on_migration?
    ENV['skip_on_db_migrate'] =~ TRUE_RE
  end

  def self.include_routes?
    ENV['routes'] =~ TRUE_RE
  end

  def self.include_models?
    true
  end

  def self.loaded_tasks=(val); @loaded_tasks = val; end
  def self.loaded_tasks; return @loaded_tasks; end

  def self.load_tasks
    return if(self.loaded_tasks)
    self.loaded_tasks = true

    Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
  end

  def self.load_requires(options)
    options[:require].each { |path| require path } if options[:require].count > 0
  end

  def self.eager_load(options)
    self.load_requires(options)
    require "annotate/active_record_patch"

    if(defined?(Rails))
      if(Rails.version.split('.').first.to_i < 3)
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
    rescue Exception
      # We might just be on an old version of Rake...
    end
    require 'rake'

    if File.exists?('./Rakefile')
      load './Rakefile'
    end
    Rake::Task[:environment].invoke rescue nil
    if(!defined?(Rails))
      # Not in a Rails project, so time to load up the parts of
      # ActiveSupport we need.
      require 'active_support'
      require 'active_support/core_ext/class/subclasses'
      require 'active_support/core_ext/string/inflections'
    end
    self.load_tasks
    Rake::Task[:set_annotation_options].invoke
  end

  def self.fallback(*args)
    return args.detect { |arg| !arg.blank? }
  end

  def self.true?(val)
    return false if(val.blank?)
    return false unless(val =~ TRUE_RE)
    return true
  end
end
