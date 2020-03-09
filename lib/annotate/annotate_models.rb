# rubocop:disable  Metrics/ModuleLength

require 'bigdecimal'

require 'annotate/constants'

module AnnotateModels
  # Annotate Models plugin use this header
  COMPAT_PREFIX    = '== Schema Info'.freeze
  COMPAT_PREFIX_MD = '## Schema Info'.freeze
  PREFIX           = '== Schema Information'.freeze
  PREFIX_MD        = '## Schema Information'.freeze
  END_MARK         = '== Schema Information End'.freeze

  SKIP_ANNOTATION_PREFIX = '# -\*- SkipSchemaAnnotations'.freeze

  MATCHED_TYPES = %w(test fixture factory serializer scaffold controller helper).freeze

  # File.join for windows reverse bar compat?
  # I dont use windows, can`t test
  UNIT_TEST_DIR         = File.join('test', "unit")
  MODEL_TEST_DIR        = File.join('test', "models") # since rails 4.0
  SPEC_MODEL_DIR        = File.join('spec', "models")
  FIXTURE_TEST_DIR      = File.join('test', "fixtures")
  FIXTURE_SPEC_DIR      = File.join('spec', "fixtures")

  # Other test files
  CONTROLLER_TEST_DIR   = File.join('test', "controllers")
  CONTROLLER_SPEC_DIR   = File.join('spec', "controllers")
  REQUEST_SPEC_DIR      = File.join('spec', "requests")
  ROUTING_SPEC_DIR      = File.join('spec', "routing")

  # Object Daddy http://github.com/flogic/object_daddy/tree/master
  EXEMPLARS_TEST_DIR    = File.join('test', "exemplars")
  EXEMPLARS_SPEC_DIR    = File.join('spec', "exemplars")

  # Machinist http://github.com/notahat/machinist
  BLUEPRINTS_TEST_DIR   = File.join('test', "blueprints")
  BLUEPRINTS_SPEC_DIR   = File.join('spec', "blueprints")

  # Factory Bot https://github.com/thoughtbot/factory_bot
  FACTORY_BOT_TEST_DIR = File.join('test', "factories")
  FACTORY_BOT_SPEC_DIR = File.join('spec', "factories")

  # Fabrication https://github.com/paulelliott/fabrication.git
  FABRICATORS_TEST_DIR  = File.join('test', "fabricators")
  FABRICATORS_SPEC_DIR  = File.join('spec', "fabricators")

  # Serializers https://github.com/rails-api/active_model_serializers
  SERIALIZERS_DIR       = File.join('app',  "serializers")
  SERIALIZERS_TEST_DIR  = File.join('test', "serializers")
  SERIALIZERS_SPEC_DIR  = File.join('spec', "serializers")

  # Controller files
  CONTROLLER_DIR        = File.join('app', "controllers")

  # Active admin registry files
  ACTIVEADMIN_DIR        = File.join('app', "admin")

  # Helper files
  HELPER_DIR            = File.join('app', "helpers")

  # Don't show limit (#) on these column types
  # Example: show "integer" instead of "integer(4)"
  NO_LIMIT_COL_TYPES = %w(integer bigint boolean).freeze

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

  MAGIC_COMMENT_MATCHER = Regexp.new(/(^#\s*encoding:.*(?:\n|r\n))|(^# coding:.*(?:\n|\r\n))|(^# -\*- coding:.*(?:\n|\r\n))|(^# -\*- encoding\s?:.*(?:\n|\r\n))|(^#\s*frozen_string_literal:.+(?:\n|\r\n))|(^# -\*- frozen_string_literal\s*:.+-\*-(?:\n|\r\n))/).freeze

  class << self
    def annotate_pattern(options = {})
      if options[:wrapper_open]
        return /(?:^(\n|\r\n)?# (?:#{options[:wrapper_open]}).*(\n|\r\n)?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?(\n|\r\n)(#.*(\n|\r\n))*(\n|\r\n)*)|^(\n|\r\n)?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?(\n|\r\n)(#.*(\n|\r\n))*(\n|\r\n)*/
      end
      /^(\n|\r\n)?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?(\n|\r\n)(#.*(\n|\r\n))*(\n|\r\n)*/
    end

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

    def test_files(root_directory)
      [
        File.join(root_directory, UNIT_TEST_DIR,  "%MODEL_NAME%_test.rb"),
        File.join(root_directory, MODEL_TEST_DIR,  "%MODEL_NAME%_test.rb"),
        File.join(root_directory, SPEC_MODEL_DIR, "%MODEL_NAME%_spec.rb")
      ]
    end

    def fixture_files(root_directory)
      [
        File.join(root_directory, FIXTURE_TEST_DIR, "%TABLE_NAME%.yml"),
        File.join(root_directory, FIXTURE_SPEC_DIR, "%TABLE_NAME%.yml"),
        File.join(root_directory, FIXTURE_TEST_DIR, "%PLURALIZED_MODEL_NAME%.yml"),
        File.join(root_directory, FIXTURE_SPEC_DIR, "%PLURALIZED_MODEL_NAME%.yml")
      ]
    end

    def scaffold_files(root_directory)
      [
        File.join(root_directory, CONTROLLER_TEST_DIR, "%PLURALIZED_MODEL_NAME%_controller_test.rb"),
        File.join(root_directory, CONTROLLER_SPEC_DIR, "%PLURALIZED_MODEL_NAME%_controller_spec.rb"),
        File.join(root_directory, REQUEST_SPEC_DIR,    "%PLURALIZED_MODEL_NAME%_spec.rb"),
        File.join(root_directory, ROUTING_SPEC_DIR,    "%PLURALIZED_MODEL_NAME%_routing_spec.rb")
      ]
    end

    def factory_files(root_directory)
      [
        File.join(root_directory, EXEMPLARS_TEST_DIR,     "%MODEL_NAME%_exemplar.rb"),
        File.join(root_directory, EXEMPLARS_SPEC_DIR,     "%MODEL_NAME%_exemplar.rb"),
        File.join(root_directory, BLUEPRINTS_TEST_DIR,    "%MODEL_NAME%_blueprint.rb"),
        File.join(root_directory, BLUEPRINTS_SPEC_DIR,    "%MODEL_NAME%_blueprint.rb"),
        File.join(root_directory, FACTORY_BOT_TEST_DIR,  "%MODEL_NAME%_factory.rb"),    # (old style)
        File.join(root_directory, FACTORY_BOT_SPEC_DIR,  "%MODEL_NAME%_factory.rb"),    # (old style)
        File.join(root_directory, FACTORY_BOT_TEST_DIR,  "%TABLE_NAME%.rb"),            # (new style)
        File.join(root_directory, FACTORY_BOT_SPEC_DIR,  "%TABLE_NAME%.rb"),            # (new style)
        File.join(root_directory, FACTORY_BOT_TEST_DIR,  "%PLURALIZED_MODEL_NAME%.rb"), # (new style)
        File.join(root_directory, FACTORY_BOT_SPEC_DIR,  "%PLURALIZED_MODEL_NAME%.rb"), # (new style)
        File.join(root_directory, FABRICATORS_TEST_DIR,   "%MODEL_NAME%_fabricator.rb"),
        File.join(root_directory, FABRICATORS_SPEC_DIR,   "%MODEL_NAME%_fabricator.rb")
      ]
    end

    def serialize_files(root_directory)
      [
        File.join(root_directory, SERIALIZERS_DIR,       "%MODEL_NAME%_serializer.rb"),
        File.join(root_directory, SERIALIZERS_TEST_DIR,  "%MODEL_NAME%_serializer_test.rb"),
        File.join(root_directory, SERIALIZERS_SPEC_DIR,  "%MODEL_NAME%_serializer_spec.rb")
      ]
    end

    def files_by_pattern(root_directory, pattern_type, options)
      case pattern_type
      when 'test'       then test_files(root_directory)
      when 'fixture'    then fixture_files(root_directory)
      when 'scaffold'   then scaffold_files(root_directory)
      when 'factory'    then factory_files(root_directory)
      when 'serializer' then serialize_files(root_directory)
      when 'additional_file_patterns'
        [options[:additional_file_patterns] || []].flatten
      when 'controller'
        [File.join(root_directory, CONTROLLER_DIR, "%PLURALIZED_MODEL_NAME%_controller.rb")]
      when 'admin'
        [File.join(root_directory, ACTIVEADMIN_DIR, "%MODEL_NAME%.rb")]
      when 'helper'
        [File.join(root_directory, HELPER_DIR, "%PLURALIZED_MODEL_NAME%_helper.rb")]
      else
        []
      end
    end

    def get_patterns(options, pattern_types = [])
      current_patterns = []
      root_dir.each do |root_directory|
        Array(pattern_types).each do |pattern_type|
          patterns = files_by_pattern(root_directory, pattern_type, options)

          current_patterns += if pattern_type.to_sym == :additional_file_patterns
                                patterns
                              else
                                patterns.map { |p| p.sub(/^[\/]*/, '') }
                              end
        end
      end
      current_patterns
    end

    # Simple quoting for the default column value
    def quote(value)
      case value
      when NilClass                 then 'NULL'
      when TrueClass                then 'TRUE'
      when FalseClass               then 'FALSE'
      when Float, Integer           then value.to_s
        # BigDecimals need to be output in a non-normalized form and quoted.
      when BigDecimal               then value.to_s('F')
      when Array                    then value.map { |v| quote(v) }
      else
        value.inspect
      end
    end

    def schema_default(klass, column)
      quote(klass.column_defaults[column.name])
    end

    def retrieve_indexes_from_table(klass)
      table_name = klass.table_name
      return [] unless table_name

      indexes = klass.connection.indexes(table_name)
      return indexes if indexes.any? || !klass.table_name_prefix

      # Try to search the table without prefix
      table_name_without_prefix = table_name.to_s.sub(klass.table_name_prefix, '')
      klass.connection.indexes(table_name_without_prefix)
    end

    # Use the column information in an ActiveRecord class
    # to create a comment block containing a line for
    # each column. The line contains the column name,
    # the type (and length), and any optional attributes
    def get_schema_info(klass, header, options = {})
      info = "# #{header}\n"
      info << get_schema_header_text(klass, options)

      max_size = max_schema_info_width(klass, options)
      md_names_overhead = 6
      md_type_allowance = 18
      bare_type_allowance = 16

      if options[:format_markdown]
        info << sprintf( "# %-#{max_size + md_names_overhead}.#{max_size + md_names_overhead}s | %-#{md_type_allowance}.#{md_type_allowance}s | %s\n", 'Name', 'Type', 'Attributes' )
        info << "# #{ '-' * ( max_size + md_names_overhead ) } | #{'-' * md_type_allowance} | #{ '-' * 27 }\n"
      end

      cols = columns(klass, options)
      cols.each do |col|
        col_type = get_col_type(col)
        attrs = []
        attrs << "default(#{schema_default(klass, col)})" unless col.default.nil? || hide_default?(col_type, options)
        attrs << 'unsigned' if col.respond_to?(:unsigned?) && col.unsigned?
        attrs << 'not null' unless col.null
        attrs << 'primary key' if klass.primary_key && (klass.primary_key.is_a?(Array) ? klass.primary_key.collect(&:to_sym).include?(col.name.to_sym) : col.name.to_sym == klass.primary_key.to_sym)

        if col_type == 'decimal'
          col_type << "(#{col.precision}, #{col.scale})"
        elsif !%w[spatial geometry geography].include?(col_type)
          if col.limit && !options[:format_yard]
            if col.limit.is_a? Array
              attrs << "(#{col.limit.join(', ')})"
            else
              col_type << "(#{col.limit})" unless hide_limit?(col_type, options)
            end
          end
        end

        # Check out if we got an array column
        attrs << 'is an Array' if col.respond_to?(:array) && col.array

        # Check out if we got a geometric column
        # and print the type and SRID
        if col.respond_to?(:geometry_type)
          attrs << "#{col.geometry_type}, #{col.srid}"
        elsif col.respond_to?(:geometric_type) && col.geometric_type.present?
          attrs << "#{col.geometric_type.to_s.downcase}, #{col.srid}"
        end

        # Check if the column has indices and print "indexed" if true
        # If the index includes another column, print it too.
        if options[:simple_indexes] && klass.table_exists?# Check out if this column is indexed
          indices = retrieve_indexes_from_table(klass)
          if indices = indices.select { |ind| ind.columns.include? col.name }
            indices.sort_by(&:name).each do |ind|
              next if ind.columns.is_a?(String)
              ind = ind.columns.reject! { |i| i == col.name }
              attrs << (ind.empty? ? "indexed" : "indexed => [#{ind.join(", ")}]")
            end
          end
        end
        col_name = if with_comments?(klass, options) && col.comment
                     "#{col.name}(#{col.comment})"
                   else
                     col.name
                   end
        if options[:format_rdoc]
          info << sprintf("# %-#{max_size}.#{max_size}s<tt>%s</tt>", "*#{col_name}*::", attrs.unshift(col_type).join(", ")).rstrip + "\n"
        elsif options[:format_yard]
          info << sprintf("# @!attribute #{col_name}") + "\n"
          ruby_class = col.respond_to?(:array) && col.array ? "Array<#{map_col_type_to_ruby_classes(col_type)}>": map_col_type_to_ruby_classes(col_type)
          info << sprintf("#   @return [#{ruby_class}]") + "\n"
        elsif options[:format_markdown]
          name_remainder = max_size - col_name.length - non_ascii_length(col_name)
          type_remainder = (md_type_allowance - 2) - col_type.length
          info << (sprintf("# **`%s`**%#{name_remainder}s | `%s`%#{type_remainder}s | `%s`", col_name, " ", col_type, " ", attrs.join(", ").rstrip)).gsub('``', '  ').rstrip + "\n"
        else
          info << format_default(col_name, max_size, col_type, bare_type_allowance, attrs)
        end
      end

      if options[:show_indexes] && klass.table_exists?
        info << get_index_info(klass, options)
      end

      if options[:show_foreign_keys] && klass.table_exists?
        info << get_foreign_key_info(klass, options)
      end

      info << get_schema_footer_text(klass, options)
    end

    def get_schema_header_text(klass, options = {})
      info = "#\n"
      if options[:format_markdown]
        info << "# Table name: `#{klass.table_name}`\n"
        info << "#\n"
        info << "# ### Columns\n"
      else
        info << "# Table name: #{klass.table_name}\n"
      end
      info << "#\n"
    end

    def get_schema_footer_text(_klass, options = {})
      info = ''
      if options[:format_rdoc]
        info << "#--\n"
        info << "# #{END_MARK}\n"
        info << "#++\n"
      else
        info << "#\n"
      end
    end

    def get_index_info(klass, options = {})
      index_info = if options[:format_markdown]
                     "#\n# ### Indexes\n#\n"
                   else
                     "#\n# Indexes\n#\n"
                   end

      indexes = retrieve_indexes_from_table(klass)
      return '' if indexes.empty?

      max_size = indexes.collect{|index| index.name.size}.max + 1
      indexes.sort_by(&:name).each do |index|
        index_info << if options[:format_markdown]
                        final_index_string_in_markdown(index)
                      else
                        final_index_string(index, max_size)
                      end
      end

      index_info
    end

    def get_col_type(col)
      if (col.respond_to?(:bigint?) && col.bigint?) || /\Abigint\b/ =~ col.sql_type
        'bigint'
      else
        (col.type || col.sql_type).to_s
      end
    end

    def index_columns_info(index)
      Array(index.columns).map do |col|
        if index.try(:orders) && index.orders[col.to_s]
          "#{col} #{index.orders[col.to_s].upcase}"
        else
          col.to_s.gsub("\r", '\r').gsub("\n", '\n')
        end
      end
    end

    def index_unique_info(index, format = :default)
      index.unique ? " #{INDEX_CLAUSES[:unique][format]}" : ''
    end

    def index_where_info(index, format = :default)
      value = index.try(:where).try(:to_s)
      if value.blank?
        ''
      else
        " #{INDEX_CLAUSES[:where][format]} #{value}"
      end
    end

    def index_using_info(index, format = :default)
      value = index.try(:using) && index.using.try(:to_sym)
      if !value.blank? && value != :btree
        " #{INDEX_CLAUSES[:using][format]} #{value}"
      else
        ''
      end
    end

    def final_index_string_in_markdown(index)
      details = sprintf(
        "%s%s%s",
        index_unique_info(index, :markdown),
        index_where_info(index, :markdown),
        index_using_info(index, :markdown)
      ).strip
      details = " (#{details})" unless details.blank?

      sprintf(
        "# * `%s`%s:\n#     * **`%s`**\n",
        index.name,
        details,
        index_columns_info(index).join("`**\n#     * **`")
      )
    end

    def final_index_string(index, max_size)
      sprintf(
        "#  %-#{max_size}.#{max_size}s %s%s%s%s",
        index.name,
        "(#{index_columns_info(index).join(',')})",
        index_unique_info(index),
        index_where_info(index),
        index_using_info(index)
      ).rstrip + "\n"
    end

    def hide_limit?(col_type, options)
      excludes =
        if options[:hide_limit_column_types].blank?
          NO_LIMIT_COL_TYPES
        else
          options[:hide_limit_column_types].split(',')
        end

      excludes.include?(col_type)
    end

    def hide_default?(col_type, options)
      excludes =
        if options[:hide_default_column_types].blank?
          NO_DEFAULT_COL_TYPES
        else
          options[:hide_default_column_types].split(',')
        end

      excludes.include?(col_type)
    end

    def get_foreign_key_info(klass, options = {})
      fk_info = if options[:format_markdown]
                  "#\n# ### Foreign Keys\n#\n"
                else
                  "#\n# Foreign Keys\n#\n"
                end

      return '' unless klass.connection.respond_to?(:supports_foreign_keys?) &&
        klass.connection.supports_foreign_keys? && klass.connection.respond_to?(:foreign_keys)

      foreign_keys = klass.connection.foreign_keys(klass.table_name)
      return '' if foreign_keys.empty?

      format_name = lambda do |fk|
        return fk.options[:column] if fk.name.blank?
        options[:show_complete_foreign_keys] ? fk.name : fk.name.gsub(/(?<=^fk_rails_)[0-9a-f]{10}$/, '...')
      end

      max_size = foreign_keys.map(&format_name).map(&:size).max + 1
      foreign_keys.sort_by {|fk| [format_name.call(fk), fk.column]}.each do |fk|
        ref_info = "#{fk.column} => #{fk.to_table}.#{fk.primary_key}"
        constraints_info = ''
        constraints_info += "ON DELETE => #{fk.on_delete} " if fk.on_delete
        constraints_info += "ON UPDATE => #{fk.on_update} " if fk.on_update
        constraints_info.strip!

        fk_info << if options[:format_markdown]
                     sprintf("# * `%s`%s:\n#     * **`%s`**\n", format_name.call(fk), constraints_info.blank? ? '' : " (_#{constraints_info}_)", ref_info)
                   else
                     sprintf("#  %-#{max_size}.#{max_size}s %s %s", format_name.call(fk), "(#{ref_info})", constraints_info).rstrip + "\n"
                   end
      end

      fk_info
    end

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

      column_pattern = /^#[\t ]+[\w\*\.`]+[\t ]+.+$/
      old_columns = old_header && old_header.scan(column_pattern).sort
      new_columns = new_header && new_header.scan(column_pattern).sort

      return false if old_columns == new_columns && !options[:force]

      abort "annotate error. #{file_name} needs to be updated, but annotate was run with `--frozen`." if options[:frozen]

      # Replace inline the old schema info with the new schema info
      wrapper_open = options[:wrapper_open] ? "# #{options[:wrapper_open]}\n" : ""
      wrapper_close = options[:wrapper_close] ? "# #{options[:wrapper_close]}\n" : ""
      wrapped_info_block = "#{wrapper_open}#{info_block}#{wrapper_close}"

      old_annotation = old_content.match(annotate_pattern(options)).to_s

      # if there *was* no old schema info or :force was passed, we simply
      # need to insert it in correct position
      if old_annotation.empty? || options[:force]
        magic_comments_block = magic_comments_as_string(old_content)
        old_content.gsub!(MAGIC_COMMENT_MATCHER, '')
        old_content.sub!(annotate_pattern(options), '')

        new_content = if %w(after bottom).include?(options[position].to_s)
                        magic_comments_block + (old_content.rstrip + "\n\n" + wrapped_info_block)
                      elsif magic_comments_block.empty?
                        magic_comments_block + wrapped_info_block + old_content.lstrip
                      else
                        magic_comments_block + "\n" + wrapped_info_block + old_content.lstrip
                      end
      else
        # replace the old annotation with the new one

        # keep the surrounding whitespace the same
        space_match = old_annotation.match(/\A(?<start>\s*).*?\n(?<end>\s*)\z/m)
        new_annotation = space_match[:start] + wrapped_info_block + space_match[:end]

        new_content = old_content.sub(annotate_pattern(options), new_annotation)
      end

      File.open(file_name, 'wb') { |f| f.puts new_content }
      true
    end

    def magic_comments_as_string(content)
      magic_comments = content.scan(MAGIC_COMMENT_MATCHER).flatten.compact

      if magic_comments.any?
        magic_comments.join
      else
        ''
      end
    end

    def remove_annotation_of_file(file_name, options = {})
      if File.exist?(file_name)
        content = File.read(file_name)
        return false if content =~ /#{SKIP_ANNOTATION_PREFIX}.*\n/

        wrapper_open = options[:wrapper_open] ? "# #{options[:wrapper_open]}\n" : ''
        content.sub!(/(#{wrapper_open})?#{annotate_pattern(options)}/, '')

        File.open(file_name, 'wb') { |f| f.puts content }

        true
      else
        false
      end
    end

    def matched_types(options)
      types = MATCHED_TYPES.dup
      types << 'admin' if options[:active_admin] =~ Annotate::Constants::TRUE_RE && !types.include?('admin')
      types << 'additional_file_patterns' if options[:additional_file_patterns].present?

      types
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

          get_patterns(options, key)
            .map { |f| resolve_filename(f, model_name, table_name) }
            .map { |f| expand_glob_into_files(f) }
            .flatten
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

    # position = :position_in_fixture or :position_in_class
    def options_with_position(options, position_in)
      options.merge(position: (options[position_in] || options[:position]))
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
    private :list_model_files_from_argument

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

    def parse_options(options = {})
      self.model_dir = split_model_dir(options[:model_dir]) if options[:model_dir]
      self.root_dir = options[:root_dir] if options[:root_dir]
    end

    def split_model_dir(option_value)
      option_value = option_value.is_a?(Array) ? option_value : option_value.split(',')
      option_value.map(&:strip).reject(&:empty?)
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

    def expand_glob_into_files(glob)
      Dir.glob(glob)
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

            get_patterns(options, matched_types(options))
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

    def resolve_filename(filename_template, model_name, table_name)
      filename_template
        .gsub('%MODEL_NAME%', model_name)
        .gsub('%PLURALIZED_MODEL_NAME%', model_name.pluralize)
        .gsub('%TABLE_NAME%', table_name || model_name.pluralize)
    end

    def classified_sort(cols)
      rest_cols = []
      timestamps = []
      associations = []
      id = nil

      cols.each do |c|
        if c.name.eql?('id')
          id = c
        elsif c.name.eql?('created_at') || c.name.eql?('updated_at')
          timestamps << c
        elsif c.name[-3, 3].eql?('_id')
          associations << c
        else
          rest_cols << c
        end
      end
      [rest_cols, timestamps, associations].each { |a| a.sort_by!(&:name) }

      ([id] << rest_cols << timestamps << associations).flatten.compact
    end

    private

    def with_comments?(klass, options)
      options[:with_comment] &&
        klass.columns.first.respond_to?(:comment) &&
        klass.columns.any? { |col| !col.comment.nil? }
    end

    def max_schema_info_width(klass, options)
      cols = columns(klass, options)

      if with_comments?(klass, options)
        max_size = cols.map do |column|
          column.name.size + (column.comment ? width(column.comment) : 0)
        end.max || 0
        max_size += 2
      else
        max_size = cols.map(&:name).map(&:size).max
      end
      max_size += options[:format_rdoc] ? 5 : 1

      max_size
    end

    def format_default(col_name, max_size, col_type, bare_type_allowance, attrs)
      sprintf("#  %s:%s %s", mb_chars_ljust(col_name, max_size), mb_chars_ljust(col_type, bare_type_allowance),  attrs.join(", ")).rstrip + "\n"
    end

    def width(string)
      string.chars.inject(0) { |acc, elem| acc + (elem.bytesize == 3 ? 2 : 1) }
    end

    def mb_chars_ljust(string, length)
      string = string.to_s
      padding = length - width(string)
      if padding > 0
        string + (' ' * padding)
      else
        string[0..length-1]
      end
    end

    def non_ascii_length(string)
      string.to_s.chars.reject(&:ascii_only?).length
    end

    def map_col_type_to_ruby_classes(col_type)
      case col_type
      when 'integer'                                       then Integer.to_s
      when 'float'                                         then Float.to_s
      when 'decimal'                                       then BigDecimal.to_s
      when 'datetime', 'timestamp', 'time'                 then Time.to_s
      when 'date'                                          then Date.to_s
      when 'text', 'string', 'binary', 'inet', 'uuid'      then String.to_s
      when 'json', 'jsonb'                                 then Hash.to_s
      when 'boolean'                                       then 'Boolean'
      end
    end

    def columns(klass, options)
      cols = klass.columns
      cols += translated_columns(klass)

      if ignore_columns = options[:ignore_columns]
        cols = cols.reject do |col|
          col.name.match(/#{ignore_columns}/)
        end
      end

      cols = cols.sort_by(&:name) if options[:sort]
      cols = classified_sort(cols) if options[:classified_sort]

      cols
    end

    ##
    # Add columns managed by the globalize gem if this gem is being used.
    def translated_columns(klass)
      return [] unless klass.respond_to? :translation_class

      ignored_cols = ignored_translation_table_colums(klass)
      klass.translation_class.columns.reject do |col|
        ignored_cols.include? col.name.to_sym
      end
    end

    ##
    # These are the columns that the globalize gem needs to work but
    # are not necessary for the models to be displayed as annotations.
    def ignored_translation_table_colums(klass)
      # Construct the foreign column name in the translations table
      # eg. Model: Car, foreign column name: car_id
      foreign_column_name = [
        klass.translation_class.to_s
             .gsub('::Translation', '').gsub('::', '_')
             .downcase,
        '_id'
      ].join.to_sym

      [
        :id,
        :created_at,
        :updated_at,
        :locale,
        foreign_column_name
      ]
    end
  end

  class BadModelFileError < LoadError
    def to_s
      "file doesn't contain a valid model class"
    end
  end
end
