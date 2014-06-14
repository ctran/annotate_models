module AnnotateModels
  # Annotate Models plugin use this header
  COMPAT_PREFIX    = "== Schema Info"
  COMPAT_PREFIX_MD = "## Schema Info"
  PREFIX           = "== Schema Information"
  PREFIX_MD        = "## Schema Information"
  END_MARK         = "== Schema Information End"
  PATTERN          = /^\n?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?\n(#.*\n)*\n*/

  # File.join for windows reverse bar compat?
  # I dont use windows, can`t test
  UNIT_TEST_DIR         = File.join("test", "unit")
  MODEL_TEST_DIR        = File.join("test", "models") # since rails 4.0
  SPEC_MODEL_DIR        = File.join("spec", "models")
  FIXTURE_TEST_DIR      = File.join("test", "fixtures")
  FIXTURE_SPEC_DIR      = File.join("spec", "fixtures")

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

  TEST_PATTERNS = [
    File.join(UNIT_TEST_DIR,  "%MODEL_NAME%_test.rb"),
    File.join(MODEL_TEST_DIR,  "%MODEL_NAME%_test.rb"),
    File.join(SPEC_MODEL_DIR, "%MODEL_NAME%_spec.rb"),
  ]

  FIXTURE_PATTERNS = [
    File.join(FIXTURE_TEST_DIR, "%TABLE_NAME%.yml"),
    File.join(FIXTURE_SPEC_DIR, "%TABLE_NAME%.yml"),
  ]

  FACTORY_PATTERNS = [
    File.join(EXEMPLARS_TEST_DIR,     "%MODEL_NAME%_exemplar.rb"),
    File.join(EXEMPLARS_SPEC_DIR,     "%MODEL_NAME%_exemplar.rb"),
    File.join(BLUEPRINTS_TEST_DIR,    "%MODEL_NAME%_blueprint.rb"),
    File.join(BLUEPRINTS_SPEC_DIR,    "%MODEL_NAME%_blueprint.rb"),
    File.join(FACTORY_GIRL_TEST_DIR,  "%MODEL_NAME%_factory.rb"),    # (old style)
    File.join(FACTORY_GIRL_SPEC_DIR,  "%MODEL_NAME%_factory.rb"),    # (old style)
    File.join(FACTORY_GIRL_TEST_DIR,  "%TABLE_NAME%.rb"),            # (new style)
    File.join(FACTORY_GIRL_SPEC_DIR,  "%TABLE_NAME%.rb"),            # (new style)
    File.join(FABRICATORS_TEST_DIR,   "%MODEL_NAME%_fabricator.rb"),
    File.join(FABRICATORS_SPEC_DIR,   "%MODEL_NAME%_fabricator.rb"),
  ]

  # Don't show limit (#) on these column types
  # Example: show "integer" instead of "integer(4)"
  NO_LIMIT_COL_TYPES = ["integer", "boolean"]

  class << self
    def model_dir
      @model_dir || "app/models"
    end

    def model_dir=(dir)
      @model_dir = dir
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
      else
        value.inspect
      end
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

      cols = klass.columns
      if options[:ignore_columns]
        cols.reject! { |col| col.name.match(/#{options[:ignore_columns]}/) }
      end
      cols = cols.sort_by(&:name) if(options[:sort])
      cols.each do |col|
        attrs = []
        attrs << "default(#{quote(col.default)})" unless col.default.nil?
        attrs << "not null" unless col.null
        attrs << "primary key" if klass.primary_key && (klass.primary_key.is_a?(Array) ? klass.primary_key.collect{|c|c.to_sym}.include?(col.name.to_sym) : col.name.to_sym == klass.primary_key.to_sym)

        col_type = (col.type || col.sql_type).to_s
        if col_type == "decimal"
          col_type << "(#{col.precision}, #{col.scale})"
        elsif col_type != "spatial"
          if (col.limit)
            if col.limit.is_a? Array
              attrs << "(#{col.limit.join(', ')})"
            else
              col_type << "(#{col.limit})" unless NO_LIMIT_COL_TYPES.include?(col_type)
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
            indices.each do |ind|
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

    # Add a schema block to a file. If the file already contains
    # a schema info block (a comment starting with "== Schema Information"), check if it
    # matches the block that is already there. If so, leave it be. If not, remove the old
    # info block and write a new one.
    # Returns true or false depending on whether the file was modified.
    #
    # === Options (opts)
    #  :force<Symbol>:: whether to update the file even if it doesn't seem to need it.
    #  :position_in_*<Symbol>:: where to place the annotated section in fixture or model file,
    #                           :before or :after. Default is :before.
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

        encoding = Regexp.new(/(^#\s*encoding:.*\n)|(^# coding:.*\n)|(^# -\*- coding:.*\n)|(^# -\*- encoding\s?:.*\n)/)
        encoding_header = old_content.match(encoding).to_s

        if old_columns == new_columns && !options[:force]
          return false
        else
          # Replace inline the old schema info with the new schema info
          new_content = old_content.sub(PATTERN, info_block + "\n")

          if new_content.end_with?(info_block + "\n")
            new_content = old_content.sub(PATTERN, "\n" + info_block)
          end

          # if there *was* no old schema info (no substitution happened) or :force was passed,
          # we simply need to insert it in correct position
          if new_content == old_content || options[:force]
            old_content.sub!(encoding, '')
            old_content.sub!(PATTERN, '')

            new_content = options[position].to_s == 'after' ?
              (encoding_header + (old_content.rstrip + "\n\n" + info_block)) :
              (encoding_header + info_block + "\n" + old_content)
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
    #  :exclude_tests<Symbol>:: whether to skip modification of test/spec files
    #  :exclude_fixtures<Symbol>:: whether to skip modification of fixture files
    #  :exclude_factories<Symbol>:: whether to skip modification of factory files
    #
    def annotate(klass, file, header, options={})
      begin
        info = get_schema_info(klass, header, options)
        did_annotate = false
        model_name = klass.name.underscore
        table_name = klass.table_name
        model_file_name = File.join(model_dir, file)

        if annotate_one_file(model_file_name, info, :position_in_class, options_with_position(options, :position_in_class))
          did_annotate = true
        end

        unless options[:exclude_tests]
          did_annotate = TEST_PATTERNS.
            map { |file| resolve_filename(file, model_name, table_name) }.
            map { |file| annotate_one_file(file, info, :position_in_test, options_with_position(options, :position_in_test)) }.
            detect { |result| result } || did_annotate
        end

        unless options[:exclude_fixtures]
          did_annotate = FIXTURE_PATTERNS.
            map { |file| resolve_filename(file, model_name, table_name) }.
            map { |file| annotate_one_file(file, info, :position_in_fixture, options_with_position(options, :position_in_fixture)) }.
            detect { |result| result } || did_annotate
        end

        unless options[:exclude_factories]
          did_annotate = FACTORY_PATTERNS.
            map { |file| resolve_filename(file, model_name, table_name) }.
            map { |file| annotate_one_file(file, info, :position_in_factory, options_with_position(options, :position_in_factory)) }.
            detect { |result| result } || did_annotate
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

    # Return a list of the model files to annotate. If we have
    # command line arguments, they're assumed to be either
    # the underscore or CamelCase versions of model names.
    # Otherwise we take all the model files in the
    # model_dir directory.
    def get_model_files(options)
      if(!options[:is_rake])
        models = ARGV.dup
        models.shift
      else
        models = []
      end
      models.reject!{|m| m.match(/^(.*)=/)}
      if models.empty?
        begin
          Dir.chdir(model_dir) do
            models = if options[:ignore_model_sub_dir]
              Dir["*.rb"]
            else
              Dir["**/*.rb"].reject{ |f| f["concerns/"] }
            end
          end
        rescue SystemCallError
          puts "No models found in directory '#{model_dir}'."
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
      begin
        get_loaded_model(model_path) or raise LoadError.new("cannot load a model from #{file}")
      rescue LoadError
        # this is for non-rails projects, which don't get Rails auto-require magic
        if Kernel.require(File.expand_path("#{model_dir}/#{model_path}"))
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

      annotated = []
      get_model_files(options).each do |file|
        annotate_model_file(annotated, file, header, options)
      end
      if annotated.empty?
        puts "Nothing annotated."
      else
        puts "Annotated (#{annotated.length}): #{annotated.join(', ')}"
      end
    end

    def annotate_model_file(annotated, file, header, options)
      begin
        klass = get_model_class(file)
        if klass && klass < ActiveRecord::Base && !klass.abstract_class? && klass.table_exists?
          if annotate(klass, file, header, options)
            annotated << klass
          end
        end
      rescue Exception => e
        puts "Unable to annotate #{file}: #{e.message}"
        puts "\t" + e.backtrace.join("\n\t") if options[:trace]
      end
    end

    def remove_annotations(options={})
      self.model_dir = options[:model_dir] if options[:model_dir]
      deannotated = []
      deannotated_klass = false
      get_model_files(options).each do |file|
        begin
          klass = get_model_class(file)
          if klass < ActiveRecord::Base && !klass.abstract_class?
            model_name = klass.name.underscore
            table_name = klass.table_name
            model_file_name = File.join(model_dir, file)
            deannotated_klass = true if(remove_annotation_of_file(model_file_name))

            (TEST_PATTERNS + FIXTURE_PATTERNS + FACTORY_PATTERNS).
              map { |file| resolve_filename(file, model_name, table_name) }.
              each do |file|
                if File.exist?(file)
                  remove_annotation_of_file(file)
                  deannotated_klass = true
                end
              end
          end
          deannotated << klass if(deannotated_klass)
        rescue Exception => e
          puts "Unable to deannotate #{file}: #{e.message}"
          puts "\t" + e.backtrace.join("\n\t") if options[:trace]
        end
      end
      puts "Removed annotations from: #{deannotated.join(', ')}"
    end

    def resolve_filename(filename_template, model_name, table_name)
      return filename_template.
        gsub('%MODEL_NAME%', model_name).
        gsub('%TABLE_NAME%', table_name || model_name.pluralize)
    end
  end
end
