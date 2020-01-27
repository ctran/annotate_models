require 'optparse'

module Annotate
  # Class for handling command line arguments
  class Parser # rubocop:disable Metrics/ClassLength
    def self.parse(args, env = {})
      new(args, env).parse
    end

    attr_reader :args, :options, :env

    DEFAULT_OPTIONS = {
      target_action: :do_annotations,
      exit: false
    }.freeze

    ANNOTATION_POSITIONS = %w[before top after bottom].freeze
    FILE_TYPE_POSITIONS = %w[position_in_class position_in_factory position_in_fixture position_in_test position_in_routes position_in_serializer].freeze
    EXCLUSION_LIST = %w[tests fixtures factories serializers].freeze
    FORMAT_TYPES = %w[bare rdoc yard markdown].freeze

    def initialize(args, env)
      @args = args
      @options = DEFAULT_OPTIONS.dup
      @env = env
    end

    def parse
      # To split up because right now this method parses and commits
      parser.parse!(args)

      commit

      options
    end

    private

    def parser
      OptionParser.new do |option_parser|
        add_options_to_parser(option_parser)
      end
    end

    def commit
      env.each_pair do |key, value|
        ENV[key] = value
      end
    end

    def add_options_to_parser(option_parser) # rubocop:disable Metrics/MethodLength
      has_set_position = {}

      option_parser.banner = 'Usage: annotate [options] [model_file]*'

      option_parser.on('--additional-file-patterns path1,path2,path3',
                       Array,
                       "Additional file paths or globs to annotate, separated by commas (e.g. `/foo/bar/%model_name%/*.rb,/baz/%model_name%.rb`)") do |additional_file_patterns|
        ENV['additional_file_patterns'] = additional_file_patterns
      end

      option_parser.on('-d',
                       '--delete',
                       'Remove annotations from all model files or the routes.rb file') do
        @options[:target_action] = :remove_annotations
      end

      option_parser.on('-p',
                       '--position [before|top|after|bottom]',
                       ANNOTATION_POSITIONS,
                       'Place the annotations at the top (before) or the bottom (after) of the model/test/fixture/factory/route/serializer file(s)') do |position|
        env['position'] = position

        FILE_TYPE_POSITIONS.each do |key|
          env[key] = position unless has_set_position[key]
        end
      end

      option_parser.on('--pc',
                       '--position-in-class [before|top|after|bottom]',
                       ANNOTATION_POSITIONS,
                       'Place the annotations at the top (before) or the bottom (after) of the model file') do |position_in_class|
        env['position_in_class'] = position_in_class
        has_set_position['position_in_class'] = true
      end

      option_parser.on('--pf',
                       '--position-in-factory [before|top|after|bottom]',
                       ANNOTATION_POSITIONS,
                       'Place the annotations at the top (before) or the bottom (after) of any factory files') do |position_in_factory|
        env['position_in_factory'] = position_in_factory
        has_set_position['position_in_factory'] = true
      end

      option_parser.on('--px',
                       '--position-in-fixture [before|top|after|bottom]',
                       ANNOTATION_POSITIONS,
                       'Place the annotations at the top (before) or the bottom (after) of any fixture files') do |position_in_fixture|
        env['position_in_fixture'] = position_in_fixture
        has_set_position['position_in_fixture'] = true
      end

      option_parser.on('--pt',
                       '--position-in-test [before|top|after|bottom]',
                       ANNOTATION_POSITIONS,
                       'Place the annotations at the top (before) or the bottom (after) of any test files') do |position_in_test|
        env['position_in_test'] = position_in_test
        has_set_position['position_in_test'] = true
      end

      option_parser.on('--pr',
                       '--position-in-routes [before|top|after|bottom]',
                       ANNOTATION_POSITIONS,
                       'Place the annotations at the top (before) or the bottom (after) of the routes.rb file') do |position_in_routes|
        env['position_in_routes'] = position_in_routes
        has_set_position['position_in_routes'] = true
      end

      option_parser.on('--ps',
                       '--position-in-serializer [before|top|after|bottom]',
                       ANNOTATION_POSITIONS,
                       'Place the annotations at the top (before) or the bottom (after) of the serializer files') do |position_in_serializer|
        env['position_in_serializer'] = position_in_serializer
        has_set_position['position_in_serializer'] = true
      end

      option_parser.on('--w',
                       '--wrapper STR',
                       'Wrap annotation with the text passed as parameter.',
                       'If --w option is used, the same text will be used as opening and closing') do |wrapper|
        env['wrapper'] = wrapper
      end

      option_parser.on('--wo',
                       '--wrapper-open STR',
                       'Annotation wrapper opening.') do |wrapper_open|
        env['wrapper_open'] = wrapper_open
      end

      option_parser.on('--wc',
                       '--wrapper-close STR',
                       'Annotation wrapper closing') do |wrapper_close|
        env['wrapper_close'] = wrapper_close
      end

      option_parser.on('-r',
                       '--routes',
                       "Annotate routes.rb with the output of 'rake routes'") do
        env['routes'] = 'true'
      end

      option_parser.on('--models',
                       "Annotate ActiveRecord models") do
        env['models'] = 'true'
      end

      option_parser.on('-a',
                       '--active-admin',
                       'Annotate active_admin models') do
        env['active_admin'] = 'true'
      end

      option_parser.on('-v',
                       '--version',
                       'Show the current version of this gem') do
        puts "annotate v#{Annotate.version}"
        @options[:exit] = true
      end

      option_parser.on('-m',
                       '--show-migration',
                       'Include the migration version number in the annotation') do
        env['include_version'] = 'yes'
      end

      option_parser.on('-k',
                       '--show-foreign-keys',
                       "List the table's foreign key constraints in the annotation") do
        env['show_foreign_keys'] = 'yes'
      end

      option_parser.on('--ck',
                       '--complete-foreign-keys',
                       'Complete foreign key names in the annotation') do
        env['show_foreign_keys'] = 'yes'
        env['show_complete_foreign_keys'] = 'yes'
      end

      option_parser.on('-i',
                       '--show-indexes',
                       "List the table's database indexes in the annotation") do
        env['show_indexes'] = 'yes'
      end

      option_parser.on('-s',
                       '--simple-indexes',
                       "Concat the column's related indexes in the annotation") do
        env['simple_indexes'] = 'yes'
      end

      option_parser.on('--model-dir dir',
                       "Annotate model files stored in dir rather than app/models, separate multiple dirs with commas") do |dir|
        env['model_dir'] = dir
      end

      option_parser.on('--root-dir dir',
                       "Annotate files stored within root dir projects, separate multiple dirs with commas") do |dir|
        env['root_dir'] = dir
      end

      option_parser.on('--ignore-model-subdirects',
                       "Ignore subdirectories of the models directory") do
        env['ignore_model_sub_dir'] = 'yes'
      end

      option_parser.on('--sort',
                       "Sort columns alphabetically, rather than in creation order") do
        env['sort'] = 'yes'
      end

      option_parser.on('--classified-sort',
                       "Sort columns alphabetically, but first goes id, then the rest columns, then the timestamp columns and then the association columns") do
        env['classified_sort'] = 'yes'
      end

      option_parser.on('-R',
                       '--require path',
                       "Additional file to require before loading models, may be used multiple times") do |path|
        env['require'] = if env['require'].present?
                           "#{env['require']},#{path}"
                         else
                           path
                         end
      end

      option_parser.on('-e',
                       '--exclude [tests,fixtures,factories,serializers]',
                       Array,
                       "Do not annotate fixtures, test files, factories, and/or serializers") do |exclusions|
        exclusions ||= EXCLUSION_LIST
        exclusions.each { |exclusion| env["exclude_#{exclusion}"] = 'yes' }
      end

      option_parser.on('-f',
                       '--format [bare|rdoc|yard|markdown]',
                       FORMAT_TYPES,
                       'Render Schema Infomation as plain/RDoc/Yard/Markdown') do |format_type|
        env["format_#{format_type}"] = 'yes'
      end

      option_parser.on('--force',
                       'Force new annotations even if there are no changes.') do
        env['force'] = 'yes'
      end

      option_parser.on('--frozen',
                       'Do not allow to change annotations. Exits non-zero if there are going to be changes to files.') do
        env['frozen'] = 'yes'
      end

      option_parser.on('--timestamp',
                       'Include timestamp in (routes) annotation') do
        env['timestamp'] = 'true'
      end

      option_parser.on('--trace',
                       'If unable to annotate a file, print the full stack trace, not just the exception message.') do
        env['trace'] = 'yes'
      end

      option_parser.on('-I',
                       '--ignore-columns REGEX',
                       "don't annotate columns that match a given REGEX (i.e., `annotate -I '^(id|updated_at|created_at)'`") do |regex|
        env['ignore_columns'] = regex
      end

      option_parser.on('--ignore-routes REGEX',
                       "don't annotate routes that match a given REGEX (i.e., `annotate -I '(mobile|resque|pghero)'`") do |regex|
        env['ignore_routes'] = regex
      end

      option_parser.on('--hide-limit-column-types VALUES',
                       "don't show limit for given column types, separated by commas (i.e., `integer,boolean,text`)") do |values|
        env['hide_limit_column_types'] = values.to_s
      end

      option_parser.on('--hide-default-column-types VALUES',
                       "don't show default for given column types, separated by commas (i.e., `json,jsonb,hstore`)") do |values|
        env['hide_default_column_types'] = values.to_s
      end

      option_parser.on('--ignore-unknown-models',
                       "don't display warnings for bad model files") do
        env['ignore_unknown_models'] = 'true'
      end

      option_parser.on('--with-comment',
                       "include database comments in model annotations") do
        env['with_comment'] = 'true'
      end
    end
  end
end
