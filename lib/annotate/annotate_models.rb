require 'bigdecimal'

module AnnotateModels
  # Annotate Models plugin use this header
  COMPAT_PREFIX    = "== Schema Info"
  COMPAT_PREFIX_MD = "## Schema Info"
  PREFIX           = "== Schema Information"
  PREFIX_MD        = "## Schema Information"
  END_MARK         = "== Schema Information End"
  PATTERN          = /^\r?\n?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?\r?\n(#.*\r?\n)*(\r?\n)*/

  MATCHED_TYPES = %w(test fixture factory serializer scaffold controller helper)

  # File.join for windows reverse bar compat?
  # I dont use windows, can`t test
  UNIT_TEST_DIR         = File.join("test", "unit")
  MODEL_TEST_DIR        = File.join("test", "models") # since rails 4.0
  SPEC_MODEL_DIR        = File.join("spec", "models")
  FIXTURE_TEST_DIR      = File.join("test", "fixtures")
  FIXTURE_SPEC_DIR      = File.join("spec", "fixtures")

  # Other test files
  CONTROLLER_TEST_DIR   = File.join("test", "controllers")
  CONTROLLER_SPEC_DIR   = File.join("spec", "controllers")
  REQUEST_SPEC_DIR      = File.join("spec", "requests")
  ROUTING_SPEC_DIR      = File.join("spec", "routing")

  # Object Daddy http://github.com/flogic/object_daddy/tree/master
  EXEMPLARS_TEST_DIR    = File.join("test", "exemplars")
  EXEMPLARS_SPEC_DIR    = File.join("spec", "exemplars")

  # Machinist http://github.com/notahat/machinist
  BLUEPRINTS_TEST_DIR   = File.join("test", "blueprints")
  BLUEPRINTS_SPEC_DIR   = File.join("spec", "blueprints")

  # Factory Girl http://github.com/thoughtbot/factory_girl
  FACTORY_GIRL_TEST_DIR = File.join("test", "factories")
  FACTORY_GIRL_SPEC_DIR = File.join("spec", "factories")

  # Fabrication https://github.com/paulelliott/fabrication.git
  FABRICATORS_TEST_DIR  = File.join("test", "fabricators")
  FABRICATORS_SPEC_DIR  = File.join("spec", "fabricators")

  # Serializers https://github.com/rails-api/active_model_serializers
  SERIALIZERS_DIR       = File.join("app",  "serializers")
  SERIALIZERS_TEST_DIR  = File.join("test", "serializers")
  SERIALIZERS_SPEC_DIR  = File.join("spec", "serializers")

  # Controller files
  CONTROLLER_DIR        = File.join("app", "controllers")

  # Helper files
  HELPER_DIR            = File.join("app", "helpers")

  # Don't show limit (#) on these column types
  # Example: show "integer" instead of "integer(4)"
  NO_LIMIT_COL_TYPES = ["integer", "boolean"]

  class << self
    def model_dir
      @model_dir.is_a?(Array) ? @model_dir : [@model_dir || "app/models"]
    end

    def model_dir=(dir)
      @model_dir = dir
    end

    def root_dir
      @root_dir.is_a?(Array) ? @root_dir : [@root_dir || ""]
    end

    def root_dir=(dir)
      @root_dir = dir
    end

    def get_patterns(pattern_types=MATCHED_TYPES)
      current_patterns = []
      root_dir.each do |root_directory|
        Array(pattern_types).each do |pattern_type|
          current_patterns += case pattern_type
          when 'test'
            [
              File.join(root_directory, UNIT_TEST_DIR,  "%MODEL_NAME%_test.rb"),
              File.join(root_directory, MODEL_TEST_DIR,  "%MODEL_NAME%_test.rb"),
              File.join(root_directory, SPEC_MODEL_DIR, "%MODEL_NAME%_spec.rb"),
            ]
          when 'fixture'
            [
              File.join(root_directory, FIXTURE_TEST_DIR, "%TABLE_NAME%.yml"),
              File.join(root_directory, FIXTURE_SPEC_DIR, "%TABLE_NAME%.yml"),
              File.join(root_directory, FIXTURE_TEST_DIR, "%PLURALIZED_MODEL_NAME%.yml"),
              File.join(root_directory, FIXTURE_SPEC_DIR, "%PLURALIZED_MODEL_NAME%.yml"),
            ]
          when 'scaffold'
            [
              File.join(root_directory, CONTROLLER_TEST_DIR, "%PLURALIZED_MODEL_NAME%_controller_test.rb"),
              File.join(root_directory, CONTROLLER_SPEC_DIR, "%PLURALIZED_MODEL_NAME%_controller_spec.rb"),
              File.join(root_directory, REQUEST_SPEC_DIR,    "%PLURALIZED_MODEL_NAME%_spec.rb"),
              File.join(root_directory, ROUTING_SPEC_DIR,    "%PLURALIZED_MODEL_NAME%_routing_spec.rb"),
            ]
          when 'factory'
            [
              File.join(root_directory, EXEMPLARS_TEST_DIR,     "%MODEL_NAME%_exemplar.rb"),
              File.join(root_directory, EXEMPLARS_SPEC_DIR,     "%MODEL_NAME%_exemplar.rb"),
              File.join(root_directory, BLUEPRINTS_TEST_DIR,    "%MODEL_NAME%_blueprint.rb"),
              File.join(root_directory, BLUEPRINTS_SPEC_DIR,    "%MODEL_NAME%_blueprint.rb"),
              File.join(root_directory, FACTORY_GIRL_TEST_DIR,  "%MODEL_NAME%_factory.rb"),    # (old style)
              File.join(root_directory, FACTORY_GIRL_SPEC_DIR,  "%MODEL_NAME%_factory.rb"),    # (old style)
              File.join(root_directory, FACTORY_GIRL_TEST_DIR,  "%TABLE_NAME%.rb"),            # (new style)
              File.join(root_directory, FACTORY_GIRL_SPEC_DIR,  "%TABLE_NAME%.rb"),            # (new style)
              File.join(root_directory, FABRICATORS_TEST_DIR,   "%MODEL_NAME%_fabricator.rb"),
              File.join(root_directory, FABRICATORS_SPEC_DIR,   "%MODEL_NAME%_fabricator.rb"),
            ]
          when 'serializer'
            [
              File.join(root_directory, SERIALIZERS_DIR,       "%MODEL_NAME%_serializer.rb"),
              File.join(root_directory, SERIALIZERS_TEST_DIR,  "%MODEL_NAME%_serializer_spec.rb"),
              File.join(root_directory, SERIALIZERS_SPEC_DIR,  "%MODEL_NAME%_serializer_spec.rb")
            ]
          when 'controller'
            [
              File.join(root_directory, CONTROLLER_DIR,  "%PLURALIZED_MODEL_NAME%_controller.rb")
            ]
          when 'helper'
            [
              File.join(root_directory, HELPER_DIR,  "%PLURALIZED_MODEL_NAME%_helper.rb")
            ]
          end
        end
      end
      current_patterns.map{ |p| p.sub(/^[\/]*/, '') }
    end

    # Simple quoting for the default column value
    def quote(value)
      case value
      when NilClass                 then "NULL"
      when TrueClass                then "TRUE"
      when FalseClass               then "FALSE"
      when Float, Fixnum, Bignum    then value.to_s
        # BigDecimals need to be output in a non-normalized form and quoted.
      when BigDecimal               then value.to_s('F')
      when Array                    then value.map {|v| quote(v)}
      else
        value.inspect
      end
    end

    def schema_default(klass, column)
      quote(klass.column_defaults[column.name])
    end

    # Use the column information in an ActiveRecord class
    # to create a comment block containing a line for
    # each column. The line contains the column name,
    # the type (and length), and any optional attributes
    def get_schema_info(klass, header, options = {})
      info = "# #{header}\n"
      info<< "#\n"
      if(options[:format_markdown])
        info<< "# Table name: `#{klass.table_name}`\n"
        info<< "#\n"
        info<< "# ### Columns\n"
      else
        info<< "# Table name: #{klass.table_name}\n"
      end
      info<< "#\n"

      max_size = klass.column_names.map{|name| name.size}.max || 0
      max_size += options[:format_rdoc] ? 5 : 1
      md_names_overhead = 6
      md_type_allowance = 18
      bare_type_allowance = 16

      if(options[:format_markdown])
        info<< sprintf( "# %-#{max_size + md_names_overhead}.#{max_size + md_names_overhead}s | %-#{md_type_allowance}.#{md_type_allowance}s | %s\n", 'Name', 'Type', 'Attributes' )
        info<< "# #{ '-' * ( max_size + md_names_overhead ) } | #{'-' * md_type_allowance} | #{ '-' * 27 }\n"
      end

      cols = if ignore_columns = options[:ignore_columns]
               klass.columns.reject do |col|
                 col.name.match(/#{ignore_columns}/)
               end
             else
               klass.columns
             end

      cols = cols.sort_by(&:name) if(options[:sort])
      cols = classified_sort(cols) if(options[:classified_sort])
      cols.each do |col|
        col_type = (col.type || col.sql_type).to_s

        attrs = []
        attrs << "default(#{schema_default(klass, col)})" unless col.default.nil? || col_type == "jsonb"
        attrs << "not null" unless col.null
        attrs << "primary key" if klass.primary_key && (klass.primary_key.is_a?(Array) ? klass.primary_key.collect{|c|c.to_sym}.include?(col.name.to_sym) : col.name.to_sym == klass.primary_key.to_sym)

        if col_type == "decimal"
          col_type << "(#{col.precision}, #{col.scale})"
        elsif col_type != "spatial"
          if (col.limit)
            if col.limit.is_a? Array
              attrs << "(#{col.limit.join(', ')})"
            else
              col_type << "(#{col.limit})" unless hide_limit?(col_type, options)
            end
          end
        end

        # Check out if we got an array column
        if col.respond_to?(:array) && col.array
          attrs << "is an Array"
        end

        # Check out if we got a geometric column
        # and print the type and SRID
        if col.respond_to?(:geometry_type)
          attrs << "#{col.geometry_type}, #{col.srid}"
        elsif col.respond_to?(:geometric_type) and col.geometric_type.present?
          attrs << "#{col.geometric_type.to_s.downcase}, #{col.srid}"
        end

        # Check if the column has indices and print "indexed" if true
        # If the index includes another column, print it too.
        if options[:simple_indexes] && klass.table_exists?# Check out if this column is indexed
          indices = klass.connection.indexes(klass.table_name)
          if indices = indices.select { |ind| ind.columns.include? col.name }
            indices.sort_by{|ind| ind.name}.each do |ind|
              ind = ind.columns.reject! { |i| i == col.name }
              attrs << (ind.length == 0 ? "indexed" : "indexed => [#{ind.join(", ")}]")
            end
          end
        end

        if options[:format_rdoc]
          info << sprintf("# %-#{max_size}.#{max_size}s<tt>%s</tt>", "*#{col.name}*::", attrs.unshift(col_type).join(", ")).rstrip + "\n"
        elsif options[:format_markdown]
          name_remainder = max_size - col.name.length
          type_remainder = (md_type_allowance - 2) - col_type.length
          info << (sprintf("# **`%s`**%#{name_remainder}s | `%s`%#{type_remainder}s | `%s`", col.name, " ", col_type, " ", attrs.join(", ").rstrip)).gsub('``', '  ').rstrip + "\n"
        else
          info << sprintf("#  %-#{max_size}.#{max_size}s:%-#{bare_type_allowance}.#{bare_type_allowance}s %s", col.name, col_type, attrs.join(", ")).rstrip + "\n"
        end
      end

      if options[:show_indexes] && klass.table_exists?
        info << get_index_info(klass, options)
      end

      if options[:show_foreign_keys] && klass.table_exists?
        info << get_foreign_key_info(klass, options)
      end

      if options[:format_rdoc]
        info << "#--\n"
        info << "# #{END_MARK}\n"
        info << "#++\n"
      else
        info << "#\n"
      end
    end

    def get_index_info(klass, options={})
      if(options[:format_markdown])
        index_info = "#\n# ### Indexes\n#\n"
      else
        index_info = "#\n# Indexes\n#\n"
      end

      indexes = klass.connection.indexes(klass.table_name)
      return "" if indexes.empty?

      max_size = indexes.collect{|index| index.name.size}.max + 1
      indexes.sort_by{|index| index.name}.each do |index|
        if(options[:format_markdown])
          index_info << sprintf("# * `%s`%s:\n#     * **`%s`**\n", index.name, index.unique ? " (_unique_)" : "", index.columns.join("`**\n#     * **`"))
        else
          index_info << sprintf("#  %-#{max_size}.#{max_size}s %s %s", index.name, "(#{index.columns.join(",")})", index.unique ? "UNIQUE" : "").rstrip + "\n"
        end
      end
      return index_info
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

    def get_foreign_key_info(klass, options={})
      if(options[:format_markdown])
        fk_info = "#\n# ### Foreign Keys\n#\n"
      else
        fk_info = "#\n# Foreign Keys\n#\n"
      end

      return "" unless klass.connection.supports_foreign_keys? && klass.connection.respond_to?(:foreign_keys)

      foreign_keys = klass.connection.foreign_keys(klass.table_name)
      return "" if foreign_keys.empty?

      max_size = foreign_keys.collect{|fk| fk.name.size}.max + 1
      foreign_keys.sort_by{|fk| fk.name}.each do |fk|
        ref_info = "#{fk.column} => #{fk.to_table}.#{fk.primary_key}"
        if(options[:format_markdown])
          fk_info << sprintf("# * `%s`:\n#     * **`%s`**\n", fk.name, ref_info)
        else
          fk_info << sprintf("#  %-#{max_size}.#{max_size}s %s", fk.name, "(#{ref_info})").rstrip + "\n"
        end
      end
      return fk_info
    end

    # Add a schema block to a file. If the file already contains
    # a schema info block (a comment starting with "== Schema Information"), check if it
    # matches the block that is already there. If so, leave it be. If not, remove the old
    # info block and write a new one.
    # Returns true or false depending on whether the file was modified.
    #
    # === Options (opts)
    #  :force<Symbol>:: whether to update the file even if it doesn't seem to need it.
    #  :position_in_*<Symbol>:: where to place the annotated section in fixture or model file,
    #                           :before, :top, :after or :bottom. Default is :before.
    #
    def annotate_one_file(file_name, info_block, position, options={})
      if File.exist?(file_name)
        old_content = File.read(file_name)
        return false if(old_content =~ /# -\*- SkipSchemaAnnotations.*\n/)

        # Ignore the Schema version line because it changes with each migration
        header_pattern = /(^# Table name:.*?\n(#.*[\r]?\n)*[\r]?)/
        old_header = old_content.match(header_pattern).to_s
        new_header = info_block.match(header_pattern).to_s

        column_pattern = /^#[\t ]+[\w\*`]+[\t ]+.+$/
        old_columns = old_header && old_header.scan(column_pattern).sort
        new_columns = new_header && new_header.scan(column_pattern).sort

        magic_comment_matcher= Regexp.new(/(^#\s*encoding:.*\n)|(^# coding:.*\n)|(^# -\*- coding:.*\n)|(^# -\*- encoding\s?:.*\n)|(^#\s*frozen_string_literal:.+\n)|(^# -\*- frozen_string_literal\s*:.+-\*-\n)/)
        magic_comments= old_content.scan(magic_comment_matcher).flatten.compact

        if old_columns == new_columns && !options[:force]
          return false
        else
          # Replace inline the old schema info with the new schema info
          new_content = old_content.sub(PATTERN, info_block + "\n")

          if new_content.end_with?(info_block + "\n")
            new_content = old_content.sub(PATTERN, "\n" + info_block)
          end

          wrapper_open = options[:wrapper_open] ? "# #{options[:wrapper_open]}\n" : ""
          wrapper_close = options[:wrapper_close] ? "# #{options[:wrapper_close]}\n" : ""
          wrapped_info_block = "#{wrapper_open}#{info_block}#{wrapper_close}"
          # if there *was* no old schema info (no substitution happened) or :force was passed,
          # we simply need to insert it in correct position
          if new_content == old_content || options[:force]
            old_content.sub!(magic_comment_matcher, '')
            old_content.sub!(PATTERN, '')

            new_content = %w(after bottom).include?(options[position].to_s) ?
              (magic_comments.join + (old_content.rstrip + "\n\n" + wrapped_info_block)) :
              (magic_comments.join + wrapped_info_block + "\n" + old_content)
          end

          File.open(file_name, "wb") { |f| f.puts new_content }
          return true
        end
      else
        return false
      end
    end

    def remove_annotation_of_file(file_name)
      if File.exist?(file_name)
        content = File.read(file_name)

        content.sub!(PATTERN, '')

        File.open(file_name, "wb") { |f| f.puts content }

        return true
      else
        return false
      end
    end

    # Given the name of an ActiveRecord class, create a schema
    # info block (basically a comment containing information
    # on the columns and their types) and put it at the front
    # of the model and fixture source files.
    # Returns true or false depending on whether the source
    # files were modified.
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
    #
    def annotate(klass, file, header, options={})
      begin
        info = get_schema_info(klass, header, options)
        did_annotate = false
        model_name = klass.name.underscore
        table_name = klass.table_name
        model_file_name = File.join(file)

        if annotate_one_file(model_file_name, info, :position_in_class, options_with_position(options, :position_in_class))
          did_annotate = true
        end

        MATCHED_TYPES.each do |key|
          exclusion_key = "exclude_#{key.pluralize}".to_sym
          position_key = "position_in_#{key}".to_sym

          unless options[exclusion_key]
            did_annotate = self.get_patterns(key).
              map { |f| resolve_filename(f, model_name, table_name) }.
              map { |f| annotate_one_file(f, info, position_key, options_with_position(options, position_key)) }.
              detect { |result| result } || did_annotate
          end
        end

        return did_annotate
      rescue Exception => e
        puts "Unable to annotate #{file}: #{e.message}"
        puts "\t" + e.backtrace.join("\n\t") if options[:trace]
      end
    end

    # position = :position_in_fixture or :position_in_class
    def options_with_position(options, position_in)
      options.merge(:position=>(options[position_in] || options[:position]))
    end

    # Return a list of the model files to annotate.
    # If we have command line arguments, they're assumed to the path
    # of model files from root dir. Otherwise we take all the model files
    # in the model_dir directory.
    def get_model_files(options)
      models = []
      if(!options[:is_rake])
        models = ARGV.dup.reject{|m| m.match(/^(.*)=/)}
      end

      if models.empty?
        begin
          model_dir.each do |dir|
            Dir.chdir(dir) do
              lst =
                if options[:ignore_model_sub_dir]
                  Dir["*.rb"].map{ |f| [dir, f] }
                else
                  Dir["**/*.rb"].reject{ |f| f["concerns/"] }.map{ |f| [dir, f] }
                end
              models.concat(lst)
            end
          end
        rescue SystemCallError
          puts "No models found in directory '#{model_dir.join("', '")}'."
          puts "Either specify models on the command line, or use the --model-dir option."
          puts "Call 'annotate --help' for more info."
          exit 1
        end
      end

      models
    end

    # Retrieve the classes belonging to the model names we're asked to process
    # Check for namespaced models in subdirectories as well as models
    # in subdirectories without namespacing.
    def get_model_class(file)
      model_path = file.gsub(/\.rb$/, '')
      model_dir.each { |dir| model_path = model_path.gsub(/^#{dir}/, '').gsub(/^\//, '') }
      begin
        get_loaded_model(model_path) or raise BadModelFileError.new
      rescue LoadError
        # this is for non-rails projects, which don't get Rails auto-require magic
        file_path = File.expand_path(file)
        if File.file?(file_path) && silence_warnings { Kernel.require(file_path) }
          retry
        elsif model_path.match(/\//)
          model_path = model_path.split('/')[1..-1].join('/').to_s
          retry
        else
          raise
        end
      end
    end

    # Retrieve loaded model class by path to the file where it's supposed to be defined.
    def get_loaded_model(model_path)
      begin
        ActiveSupport::Inflector.constantize(ActiveSupport::Inflector.camelize(model_path))
      rescue
        # Revert to the old way but it is not really robust
        ObjectSpace.each_object(::Class).
          select do |c|
            Class === c and    # note: we use === to avoid a bug in activesupport 2.3.14 OptionMerger vs. is_a?
            c.ancestors.respond_to?(:include?) and  # to fix FactoryGirl bug, see https://github.com/ctran/annotate_models/pull/82
            c.ancestors.include?(ActiveRecord::Base)
          end.
          detect { |c| ActiveSupport::Inflector.underscore(c.to_s) == model_path }
      end
    end

    # We're passed a name of things that might be
    # ActiveRecord models. If we can find the class, and
    # if its a subclass of ActiveRecord::Base,
    # then pass it to the associated block
    def do_annotations(options={})
      header = options[:format_markdown] ? PREFIX_MD.dup : PREFIX.dup

      if options[:include_version]
        version = ActiveRecord::Migrator.current_version rescue 0
        if version > 0
          header << "\n# Schema version: #{version}"
        end
      end

      self.model_dir = options[:model_dir] if options[:model_dir]
      self.root_dir = options[:root_dir] if options[:root_dir]

      annotated = []
      get_model_files(options).each do |file|
        annotate_model_file(annotated, File.join(file), header, options)
      end
      if annotated.empty?
        puts "Model files unchanged."
      else
        puts "Annotated (#{annotated.length}): #{annotated.join(', ')}"
      end
    end

    def annotate_model_file(annotated, file, header, options)
      begin
        return false if (/# -\*- SkipSchemaAnnotations.*/ =~ (File.exist?(file) ? File.read(file) : '') )
        klass = get_model_class(file)
        if klass && klass < ActiveRecord::Base && !klass.abstract_class? && klass.table_exists?
          if annotate(klass, file, header, options)
            annotated << file
          end
        end
      rescue BadModelFileError => e
        unless options[:ignore_unknown_models]
          puts "Unable to annotate #{file}: #{e.message}"
          puts "\t" + e.backtrace.join("\n\t") if options[:trace]
        end
      rescue Exception => e
        puts "Unable to annotate #{file}: #{e.message}"
        puts "\t" + e.backtrace.join("\n\t") if options[:trace]
      end
    end

    def remove_annotations(options={})
      self.model_dir = options[:model_dir] if options[:model_dir]
      self.root_dir = options[:root_dir] if options[:root_dir]
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
            deannotated_klass = true if(remove_annotation_of_file(model_file_name))

            get_patterns.
              map { |f| resolve_filename(f, model_name, table_name) }.
              each do |f|
                if File.exist?(f)
                  remove_annotation_of_file(f)
                  deannotated_klass = true
                end
              end
          end
          deannotated << klass if(deannotated_klass)
        rescue Exception => e
          puts "Unable to deannotate #{File.join(file)}: #{e.message}"
          puts "\t" + e.backtrace.join("\n\t") if options[:trace]
        end
      end
      puts "Removed annotations from: #{deannotated.join(', ')}"
    end

    def resolve_filename(filename_template, model_name, table_name)
      return filename_template.
        gsub('%MODEL_NAME%', model_name).
        gsub('%PLURALIZED_MODEL_NAME%', model_name.pluralize).
        gsub('%TABLE_NAME%', table_name || model_name.pluralize)
    end

    def classified_sort(cols)
      rest_cols = []
      timestamps = []
      associations = []
      id = nil

      cols = cols.each do |c|
        if c.name.eql?("id")
          id = c
        elsif (c.name.eql?("created_at") || c.name.eql?("updated_at"))
          timestamps << c
        elsif c.name[-3,3].eql?("_id")
          associations << c
        else
          rest_cols << c
        end
      end
      [rest_cols, timestamps, associations].each {|a| a.sort_by!(&:name) }

      return ([id] << rest_cols << timestamps << associations).flatten
    end

    # Ignore warnings for the duration of the block ()
    def silence_warnings
      old_verbose, $VERBOSE = $VERBOSE, nil
      yield
    ensure
      $VERBOSE = old_verbose
    end
  end

  class BadModelFileError < LoadError
    def to_s
      "file doesn't contain a valid model class"
    end
  end
end
