# rubocop:disable  Metrics/ModuleLength

require 'bigdecimal'

require_relative './annotate_models/files'
require_relative './annotate_models/schema_info'

module AnnotateModels
  TRUE_RE = /^(true|t|yes|y|1)$/i

  # Annotate Models plugin use this header
  COMPAT_PREFIX    = '== Schema Info'.freeze
  COMPAT_PREFIX_MD = '## Schema Info'.freeze
  PREFIX           = '== Schema Information'.freeze
  PREFIX_MD        = '## Schema Information'.freeze
  END_MARK         = '== Schema Information End'.freeze

  SKIP_ANNOTATION_PREFIX = '# -\*- SkipSchemaAnnotations'.freeze

  MATCHED_TYPES = %w(test fixture factory serializer scaffold controller helper).freeze

  # Don't show limit (#) on these column types
  # Example: show "integer" instead of "integer(4)"
  NO_LIMIT_COL_TYPES = %w(integer boolean).freeze

  # Don't show default value for these column types
  NO_DEFAULT_COL_TYPES = %w(json jsonb hstore).freeze

  INDEX_CLAUSES = {
    unique: {
      default: 'UNIQUE',
      markdown: '_unique_'
    },
    where: {
      default: 'WHERE',
      markdown: '_where_'
    },
    using: {
      default: 'USING',
      markdown: '_using_'
    }
  }.freeze

  class << self
    def model_dir
      @model_dir.is_a?(Array) ? @model_dir : [@model_dir || 'app/models']
    end

    attr_writer :model_dir

    def root_dir
      if @root_dir.blank?
        ['']
      elsif @root_dir.is_a?(String)
        @root_dir.split(',')
      else
        @root_dir
      end
    end

    attr_writer :root_dir

    # Add a schema block to a file. If the file already contains
    # a schema info block (a comment starting with "== Schema Information"),
    # check if it matches the block that is already there. If so, leave it be.
    # If not, remove the old info block and write a new one.
    #
    # == Returns:
    # true or false depending on whether the file was modified.
    #
    # === Options (opts)
    #  :force<Symbol>:: whether to update the file even if it doesn't seem to need it.
    #  :position_in_*<Symbol>:: where to place the annotated section in fixture or model file,
    #                           :before, :top, :after or :bottom. Default is :before.
    #
    def annotate_one_file(file_name, info_block, position, options = {})
      return false unless File.exist?(file_name)

      old_content = File.read(file_name)
      return false if old_content =~ /#{SKIP_ANNOTATION_PREFIX}.*\n/

      # Ignore the Schema version line because it changes with each migration
      header_pattern = /(^# Table name:.*?\n(#.*[\r]?\n)*[\r]?)/
      old_header = old_content.match(header_pattern).to_s
      new_header = info_block.match(header_pattern).to_s

      column_pattern = /^#[\t ]+[\w\*`]+[\t ]+.+$/
      old_columns = old_header && old_header.scan(column_pattern).sort
      new_columns = new_header && new_header.scan(column_pattern).sort

      magic_comments_block = magic_comments_as_string(old_content)

      return false if old_columns == new_columns && !options[:force]

      # Replace inline the old schema info with the new schema info
      new_content = old_content.sub(annotate_pattern(options), info_block + "\n")

      if new_content.end_with?(info_block + "\n")
        new_content = old_content.sub(annotate_pattern(options), "\n" + info_block)
      end

      wrapper_open = options[:wrapper_open] ? "# #{options[:wrapper_open]}\n" : ""
      wrapper_close = options[:wrapper_close] ? "# #{options[:wrapper_close]}\n" : ""
      wrapped_info_block = "#{wrapper_open}#{info_block}#{wrapper_close}"
      # if there *was* no old schema info (no substitution happened) or :force was passed,
      # we simply need to insert it in correct position
      if new_content == old_content || options[:force]
        old_content.gsub!(magic_comment_matcher, '')
        old_content.sub!(annotate_pattern(options), '')

        new_content = if %w(after bottom).include?(options[position].to_s)
                        magic_comments_block + (old_content.rstrip + "\n\n" + wrapped_info_block)
                      else
                        magic_comments_block + wrapped_info_block + "\n" + old_content
                      end
      end

      File.open(file_name, 'wb') { |f| f.puts new_content }
      true
    end

    # Given the name of an ActiveRecord class, create a schema
    # info block (basically a comment containing information
    # on the columns and their types) and put it at the front
    # of the model and fixture source files.
    #
    # === Options (opts)
    #  :position_in_class<Symbol>:: where to place the annotated section in model file
    #  :position_in_test<Symbol>:: where to place the annotated section in test/spec file(s)
    #  :position_in_fixture<Symbol>:: where to place the annotated section in fixture file
    #  :position_in_factory<Symbol>:: where to place the annotated section in factory file
    #  :position_in_serializer<Symbol>:: where to place the annotated section in serializer file
    #  :exclude_tests<Symbol>:: whether to skip modification of test/spec files
    #  :exclude_fixtures<Symbol>:: whether to skip modification of fixture files
    #  :exclude_factories<Symbol>:: whether to skip modification of factory files
    #  :exclude_serializers<Symbol>:: whether to skip modification of serializer files
    #  :exclude_scaffolds<Symbol>:: whether to skip modification of scaffold files
    #  :exclude_controllers<Symbol>:: whether to skip modification of controller files
    #  :exclude_helpers<Symbol>:: whether to skip modification of helper files
    #  :exclude_sti_subclasses<Symbol>:: whether to skip modification of files for STI subclasses
    #
    # == Returns:
    # an array of file names that were annotated.
    #
    def annotate(klass, file, header, options = {})
      begin
        klass.reset_column_information
        info = get_schema_info(klass, header, options)
        model_name = klass.name.underscore
        table_name = klass.table_name
        model_file_name = File.join(file)
        annotated = []

        if annotate_one_file(model_file_name, info, :position_in_class, options_with_position(options, :position_in_class))
          annotated << model_file_name
        end

        matched_types(options).each do |key|
          exclusion_key = "exclude_#{key.pluralize}".to_sym
          position_key = "position_in_#{key}".to_sym

          # Same options for active_admin models
          if key == 'admin'
            exclusion_key = 'exclude_class'.to_sym
            position_key = 'position_in_class'.to_sym
          end

          next if options[exclusion_key]
          get_patterns(key)
            .map { |f| resolve_filename(f, model_name, table_name) }
            .each do |f|
              if annotate_one_file(f, info, position_key, options_with_position(options, position_key))
                annotated << f
              end
            end
        end
      rescue StandardError => e
        $stderr.puts "Unable to annotate #{file}: #{e.message}"
        $stderr.puts "\t" + e.backtrace.join("\n\t") if options[:trace]
      end

      annotated
    end

    # Return a list of the model files to annotate.
    # If we have command line arguments, they're assumed to the path
    # of model files from root dir. Otherwise we take all the model files
    # in the model_dir directory.
    def get_model_files(options)
      model_files = []

      model_files = list_model_files_from_argument unless options[:is_rake]

      return model_files unless model_files.empty?

      model_dir.each do |dir|
        Dir.chdir(dir) do
          list = if options[:ignore_model_sub_dir]
                   Dir["*.rb"].map { |f| [dir, f] }
                 else
                   Dir["**/*.rb"].reject { |f| f["concerns/"] }.map { |f| [dir, f] }
                 end
          model_files.concat(list)
        end
      end

      model_files
    rescue SystemCallError
      $stderr.puts "No models found in directory '#{model_dir.join("', '")}'."
      $stderr.puts "Either specify models on the command line, or use the --model-dir option."
      $stderr.puts "Call 'annotate --help' for more info."
      exit 1
    end

    # Retrieve loaded model class by path to the file where it's supposed to be defined.
    def get_loaded_model_by_path(model_path)
      ActiveSupport::Inflector.constantize(ActiveSupport::Inflector.camelize(model_path))
    rescue StandardError, LoadError
      # Revert to the old way but it is not really robust
      ObjectSpace.each_object(::Class)
                 .select do |c|
                    Class === c && # note: we use === to avoid a bug in activesupport 2.3.14 OptionMerger vs. is_a?
                      c.ancestors.respond_to?(:include?) && # to fix FactoryGirl bug, see https://github.com/ctran/annotate_models/pull/82
                      c.ancestors.include?(ActiveRecord::Base)
                  end.detect { |c| ActiveSupport::Inflector.underscore(c.to_s) == model_path }
    end

    # We're passed a name of things that might be
    # ActiveRecord models. If we can find the class, and
    # if its a subclass of ActiveRecord::Base,
    # then pass it to the associated block
    def do_annotations(options = {})
      parse_options(options)

      header = options[:format_markdown] ? PREFIX_MD.dup : PREFIX.dup
      version = ActiveRecord::Migrator.current_version rescue 0
      if options[:include_version] && version > 0
        header << "\n# Schema version: #{version}"
      end

      annotated = []
      get_model_files(options).each do |path, filename|
        annotate_model_file(annotated, File.join(path, filename), header, options)
      end

      if annotated.empty?
        puts 'Model files unchanged.'
      else
        puts "Annotated (#{annotated.length}): #{annotated.join(', ')}"
      end
    end

    def annotate_model_file(annotated, file, header, options)
      begin
        return false if /#{SKIP_ANNOTATION_PREFIX}.*/ =~ (File.exist?(file) ? File.read(file) : '')
        klass = get_model_class(file)
        do_annotate = klass &&
          klass < ActiveRecord::Base &&
          (!options[:exclude_sti_subclasses] || !(klass.superclass < ActiveRecord::Base && klass.table_name == klass.superclass.table_name)) &&
          !klass.abstract_class? &&
          klass.table_exists?

        annotated.concat(annotate(klass, file, header, options)) if do_annotate
      rescue BadModelFileError => e
        unless options[:ignore_unknown_models]
          $stderr.puts "Unable to annotate #{file}: #{e.message}"
          $stderr.puts "\t" + e.backtrace.join("\n\t") if options[:trace]
        end
      rescue StandardError => e
        $stderr.puts "Unable to annotate #{file}: #{e.message}"
        $stderr.puts "\t" + e.backtrace.join("\n\t") if options[:trace]
      end
    end

    def remove_annotations(options = {})
      parse_options(options)

      deannotated = []
      deannotated_klass = false
      get_model_files(options).each do |file|
        file = File.join(file)
        begin
          klass = get_model_class(file)
          if klass < ActiveRecord::Base && !klass.abstract_class?
            model_name = klass.name.underscore
            table_name = klass.table_name
            model_file_name = file
            deannotated_klass = true if remove_annotation_of_file(model_file_name, options)

            get_patterns(matched_types(options))
              .map { |f| resolve_filename(f, model_name, table_name) }
              .each do |f|
                if File.exist?(f)
                  remove_annotation_of_file(f, options)
                  deannotated_klass = true
                end
              end
          end
          deannotated << klass if deannotated_klass
        rescue StandardError => e
          $stderr.puts "Unable to deannotate #{File.join(file)}: #{e.message}"
          $stderr.puts "\t" + e.backtrace.join("\n\t") if options[:trace]
        end
      end
      puts "Removed annotations from: #{deannotated.join(', ')}"
    end

    private

    def annotate_pattern(options = {})
      if options[:wrapper_open]
        return /(?:^(\n|\r\n)?# (?:#{options[:wrapper_open]}).*(\n|\r\n)?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?(\n|\r\n)(#.*(\n|\r\n))*(\n|\r\n)*)|^(\n|\r\n)?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?(\n|\r\n)(#.*(\n|\r\n))*(\n|\r\n)*/
      end
      /^(\n|\r\n)?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?(\n|\r\n)(#.*(\n|\r\n))*(\n|\r\n)*/
    end

    def get_patterns(pattern_types = [])
      current_patterns = []
      root_dir.each do |root_directory|
        Array(pattern_types).each do |pattern_type|
          current_patterns += files_by_pattern(root_directory, pattern_type)
        end
      end
      current_patterns.map { |p| p.sub(/^[\/]*/, '') }
    end

    def files_by_pattern(root_directory, pattern_type)
      Files.by_pattern(root_directory, pattern_type)
    end

    # Use the column information in an ActiveRecord class
    # to create a comment block containing a line for
    # each column. The line contains the column name,
    # the type (and length), and any optional attributes
    def get_schema_info(klass, header, options = {})
      SchemaInfo.generate(klass, header, options)
    end

    def resolve_filename(filename_template, model_name, table_name)
      filename_template
        .gsub('%MODEL_NAME%', model_name)
        .gsub('%PLURALIZED_MODEL_NAME%', model_name.pluralize)
        .gsub('%TABLE_NAME%', table_name || model_name.pluralize)
    end

    def magic_comments_as_string(content)
      magic_comments = content.scan(magic_comment_matcher).flatten.compact

      if magic_comments.any?
        magic_comments.join + "\n"
      else
        ''
      end
    end

    def magic_comment_matcher
      Regexp.new(/(^#\s*encoding:.*(?:\n|r\n))|(^# coding:.*(?:\n|\r\n))|(^# -\*- coding:.*(?:\n|\r\n))|(^# -\*- encoding\s?:.*(?:\n|\r\n))|(^#\s*frozen_string_literal:.+(?:\n|\r\n))|(^# -\*- frozen_string_literal\s*:.+-\*-(?:\n|\r\n))/)
    end

    def matched_types(options)
      types = MATCHED_TYPES
      types << 'admin' if options[:active_admin] =~ TRUE_RE && !types.include?('admin')

      types
    end

    # position = :position_in_fixture or :position_in_class
    def options_with_position(options, position_in)
      options.merge(position: (options[position_in] || options[:position]))
    end

    def list_model_files_from_argument
      return [] if ARGV.empty?

      specified_files = ARGV.map { |file| File.expand_path(file) }

      model_files = model_dir.flat_map do |dir|
        absolute_dir_path = File.expand_path(dir)
        specified_files
          .find_all { |file| file.start_with?(absolute_dir_path) }
          .map { |file| [dir, file.sub("#{absolute_dir_path}/", '')] }
      end

      if model_files.size != specified_files.size
        puts "The specified file could not be found in directory '#{model_dir.join("', '")}'."
        puts "Call 'annotate --help' for more info."
        exit 1
      end

      model_files
    end

    def parse_options(options = {})
      self.model_dir = split_model_dir(options[:model_dir]) if options[:model_dir]
      self.root_dir = options[:root_dir] if options[:root_dir]
    end

    def split_model_dir(option_value)
      option_value = option_value.is_a?(Array) ? option_value : option_value.split(',')
      option_value.map(&:strip).reject(&:empty?)
    end

    # Retrieve loaded model class
    def get_loaded_model(model_path, file)
      loaded_model_class = get_loaded_model_by_path(model_path)
      return loaded_model_class if loaded_model_class

      # We cannot get loaded model when `model_path` is loaded by Rails
      # auto_load/eager_load paths. Try all possible model paths one by one.
      absolute_file = File.expand_path(file)
      model_paths =
        $LOAD_PATH.select { |path| absolute_file.include?(path) }
                  .map { |path| absolute_file.sub(path, '').sub(/\.rb$/, '').sub(/^\//, '') }
      model_paths
        .map { |path| get_loaded_model_by_path(path) }
        .find { |loaded_model| !loaded_model.nil? }
    end

    def remove_annotation_of_file(file_name, options = {})
      return false unless File.exist?(file_name)

      content = File.read(file_name)
      return false if content =~ /#{SKIP_ANNOTATION_PREFIX}.*\n/

      wrapper_open = options[:wrapper_open] ? "# #{options[:wrapper_open]}\n" : ''
      content.sub!(/(#{wrapper_open})?#{annotate_pattern(options)}/, '')

      File.open(file_name, 'wb') { |f| f.puts content }
      true
    end

    # Retrieve the classes belonging to the model names we're asked to process
    # Check for namespaced models in subdirectories as well as models
    # in subdirectories without namespacing.
    def get_model_class(file)
      model_path = file.gsub(/\.rb$/, '')
      model_dir.each { |dir| model_path = model_path.gsub(/^#{dir}/, '').gsub(/^\//, '') }
      begin
        get_loaded_model(model_path, file) || raise(BadModelFileError.new)
      rescue LoadError
        # this is for non-rails projects, which don't get Rails auto-require magic
        file_path = File.expand_path(file)
        if File.file?(file_path) && Kernel.require(file_path)
          retry
        elsif model_path =~ /\//
          model_path = model_path.split('/')[1..-1].join('/').to_s
          retry
        else
          raise
        end
      end
    end
  end

  class BadModelFileError < LoadError
    def to_s
      "file doesn't contain a valid model class"
    end
  end
end
