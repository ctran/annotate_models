module AnnotateModels
  # Annotate Models plugin use this header
  COMPAT_PREFIX    = "== Schema Info"
  COMPAT_PREFIX_MD = "## Schema Info"
  PREFIX           = "== Schema Information"
  PREFIX_MD        = "## Schema Information"
  END_MARK         = "== Schema Information End"
  PATTERN          = /^\n?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?\n(#.*\n)*\n/

  # File.join for windows reverse bar compat?
  # I dont use windows, can`t test
  UNIT_TEST_DIR         = File.join("test", "unit"  )
  SPEC_MODEL_DIR        = File.join("spec", "models")
  FIXTURE_TEST_DIR      = File.join("test", "fixtures")
  FIXTURE_SPEC_DIR      = File.join("spec", "fixtures")
  FIXTURE_DIRS = ["test/fixtures","spec/fixtures"]

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
      info<< "# Table name: #{klass.table_name}\n"
      info<< "#\n"

      max_size = klass.column_names.map{|name| name.size}.max || 0
      max_size += options[:format_rdoc] ? 5 : 1

      if(options[:format_markdown])
        info<< sprintf( "# %-#{max_size + 4}.#{max_size + 4}s | %-18.18s | %s\n", 'Field', 'Type', 'Attributes' )
        info<< "# #{ '-' * ( max_size + 4 ) } | #{'-' * 18} | #{ '-' * 25 }\n"
      end

      cols = klass.columns
      cols = cols.sort_by(&:name) if(options[:sort])
      cols.each do |col|
        attrs = []
        attrs << "default(#{quote(col.default)})" unless col.default.nil?
        attrs << "not null" unless col.null
        attrs << "primary key" if klass.primary_key && col.name.to_sym == klass.primary_key.to_sym

        col_type = (col.type || col.sql_type).to_s
        if col_type == "decimal"
          col_type << "(#{col.precision}, #{col.scale})"
        else
          if (col.limit)
            col_type << "(#{col.limit})" unless NO_LIMIT_COL_TYPES.include?(col_type)
          end
        end
       
        # Check out if we got a geometric column
        # and print the type and SRID
        if col.respond_to?(:geometry_type)
          attrs << "#{col.geometry_type}, #{col.srid}"
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
          info << sprintf("# **%-#{max_size}.#{max_size}s** | `%-16.16s` | `%s`", col.name, col_type, attrs.join(", ").rstrip) + "\n"
        else
          info << sprintf("#  %-#{max_size}.#{max_size}s:%-16.16s %s", col.name, col_type, attrs.join(", ")).rstrip + "\n"
        end
      end

      if options[:show_indexes] && klass.table_exists?
        info << get_index_info(klass)
      end

      if options[:format_rdoc]
        info << "#--\n"
        info << "# #{END_MARK}\n"
        info << "#++\n\n"
      else
        info << "#\n\n"
      end
    end

    def get_index_info(klass)
      index_info = "#\n# Indexes\n#\n"

      indexes = klass.connection.indexes(klass.table_name)
      return "" if indexes.empty?

      max_size = indexes.collect{|index| index.name.size}.max + 1
      indexes.sort_by{|index| index.name}.each do |index|
        index_info << sprintf("#  %-#{max_size}.#{max_size}s %s %s", index.name, "(#{index.columns.join(",")})", index.unique ? "UNIQUE" : "").rstrip + "\n"
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
    #  :position<Symbol>:: where to place the annotated section in fixture or model file,
    #                      :before or :after. Default is :before.
    #  :position_in_class<Symbol>:: where to place the annotated section in model file
    #  :position_in_fixture<Symbol>:: where to place the annotated section in fixture file
    #  :position_in_others<Symbol>:: where to place the annotated section in the rest of
    #                      supported files
    #
    def annotate_one_file(file_name, info_block, options={})
      if File.exist?(file_name)
        old_content = File.read(file_name)
        return false if(old_content =~ /# -\*- SkipSchemaAnnotations.*\n/)

        # Ignore the Schema version line because it changes with each migration
        header_pattern = /(^# Table name:.*?\n(#.*[\r]?\n)*[\r]?\n)/
        old_header = old_content.match(header_pattern).to_s
        new_header = info_block.match(header_pattern).to_s

        column_pattern = /^#[\t ]+\w+[\t ]+.+$/
        old_columns = old_header && old_header.scan(column_pattern).sort
        new_columns = new_header && new_header.scan(column_pattern).sort

        encoding = Regexp.new(/(^#\s*encoding:.*\n)|(^# coding:.*\n)|(^# -\*- coding:.*\n)/)
        encoding_header = old_content.match(encoding).to_s

        if old_columns == new_columns && !options[:force]
          false
        else
          
# todo: figure out if we need to extract any logic from this merge chunk
# <<<<<<< HEAD
#           # Replace the old schema info with the new schema info
#           new_content = old_content.sub(/^# #{COMPAT_PREFIX}.*?\n(#.*\n)*\n*/, info_block)
#           # But, if there *was* no old schema info, we simply need to insert it
#           if new_content == old_content
#             old_content.sub!(encoding, '')
#             new_content = options[:position] == 'after' ?
#               (encoding_header + (old_content =~ /\n$/ ? old_content : old_content + "\n") + info_block) :
#               (encoding_header + info_block + old_content)
#           end
# =======

          # Strip the old schema info, and insert new schema info.
          old_content.sub!(encoding, '')
          old_content.sub!(PATTERN, '')
          
          new_content = (options[:position] || 'before').to_s == 'after' ?
            (encoding_header + (old_content.rstrip + "\n\n" + info_block)) :
            (encoding_header + info_block + old_content)

          File.open(file_name, "wb") { |f| f.puts new_content }
          true
        end
      end
    end
    
    def remove_annotation_of_file(file_name)
      if File.exist?(file_name)
        content = File.read(file_name)
        content.sub!(PATTERN, '')
        File.open(file_name, "wb") { |f| f.puts content }
      end
    end

    # Given the name of an ActiveRecord class, create a schema
    # info block (basically a comment containing information
    # on the columns and their types) and put it at the front
    # of the model and fixture source files.
    # Returns true or false depending on whether the source
    # files were modified.
    def annotate(klass, file, header, options={})
      info = get_schema_info(klass, header, options)
      annotated = false
      model_name = klass.name.underscore
      model_file_name = File.join(model_dir, file)

      if annotate_one_file(model_file_name, info, options_with_position(options, :position_in_class))
        annotated = true
      end

      unless options[:exclude_tests]
        [
          find_test_file(UNIT_TEST_DIR,      "#{model_name}_test.rb"), # test
          find_test_file(SPEC_MODEL_DIR,     "#{model_name}_spec.rb"), # spec
        ].each do |file|
          # todo: add an option "position_in_test" -- or maybe just ask if anyone ever wants different positions for model vs. test vs. fixture
          if annotate_one_file(file, info, options_with_position(options, :position_in_fixture))
            annotated = true
          end
        end
      end

      unless options[:exclude_fixtures]
        [
         File.join(FIXTURE_TEST_DIR,       "#{klass.table_name}.yml"),     # fixture
         File.join(FIXTURE_SPEC_DIR,       "#{klass.table_name}.yml"),     # fixture
         File.join(EXEMPLARS_TEST_DIR,     "#{model_name}_exemplar.rb"),   # Object Daddy
         File.join(EXEMPLARS_SPEC_DIR,     "#{model_name}_exemplar.rb"),   # Object Daddy
         File.join(BLUEPRINTS_TEST_DIR,    "#{model_name}_blueprint.rb"),  # Machinist Blueprints
         File.join(BLUEPRINTS_SPEC_DIR,    "#{model_name}_blueprint.rb"),  # Machinist Blueprints
         File.join(FACTORY_GIRL_TEST_DIR,  "#{model_name}_factory.rb"),    # Factory Girl Factories
         File.join(FACTORY_GIRL_SPEC_DIR,  "#{model_name}_factory.rb"),    # Factory Girl Factories
         File.join(FABRICATORS_TEST_DIR,   "#{model_name}_fabricator.rb"), # Fabrication Fabricators
         File.join(FABRICATORS_SPEC_DIR,   "#{model_name}_fabricator.rb"), # Fabrication Fabricators
        ].each do |file|
          if annotate_one_file(file, info, options_with_position(options, :position_in_fixture))
            annotated = true
          end
        end
      end

      annotated
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
              Dir["**/*.rb"]
            end
          end
        rescue SystemCallError
          puts "No models found in directory '#{model_dir}'."
          puts "Either specify models on the command line, or use the --model-dir option."
          puts "Call 'annotate --help' for more info."
          exit 1;
        end
      end
      models
    end
  
    # Retrieve the classes belonging to the model names we're asked to process
    # Check for namespaced models in subdirectories as well as models
    # in subdirectories without namespacing.
    def get_model_class(file)
      # this is for non-rails projects, which don't get Rails auto-require magic
      require File.expand_path("#{model_dir}/#{file}")

      model_path = file.gsub(/\.rb$/, '')
      get_loaded_model(model_path) || get_loaded_model(model_path.split('/').last)
    end

    # Retrieve loaded model class by path to the file where it's supposed to be defined.
    def get_loaded_model(model_path)
      ObjectSpace.each_object(::Class).
        select do |c|
          Class === c and    # note: we use === to avoid a bug in activesupport 2.3.14 OptionMerger vs. is_a?
          c.ancestors.respond_to?(:include?) and  # to fix FactoryGirl bug, see https://github.com/ctran/annotate_models/pull/82
          c.ancestors.include?(ActiveRecord::Base) 
        end.
        detect { |c| ActiveSupport::Inflector.underscore(c) == model_path }
    end

    # We're passed a name of things that might be
    # ActiveRecord models. If we can find the class, and
    # if its a subclass of ActiveRecord::Base,
    # then pass it to the associated block
    def do_annotations(options={})
      if options[:require]
        options[:require].each do |path|
          require path
        end
      end

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
        if klass && klass < ActiveRecord::Base && !klass.abstract_class?
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
      get_model_files(options).each do |file|
        begin
          klass = get_model_class(file)
          if klass < ActiveRecord::Base && !klass.abstract_class?
            deannotated << klass

            model_name = klass.name.underscore
            model_file_name = File.join(model_dir, file)
            remove_annotation_of_file(model_file_name)

            [
             File.join(UNIT_TEST_DIR,          "#{model_name}_test.rb"),
             File.join(SPEC_MODEL_DIR,         "#{model_name}_spec.rb"),
             File.join(FIXTURE_TEST_DIR,       "#{klass.table_name}.yml"),     # fixture
             File.join(FIXTURE_SPEC_DIR,       "#{klass.table_name}.yml"),     # fixture
             File.join(EXEMPLARS_TEST_DIR,     "#{model_name}_exemplar.rb"),   # Object Daddy
             File.join(EXEMPLARS_SPEC_DIR,     "#{model_name}_exemplar.rb"),   # Object Daddy
             File.join(BLUEPRINTS_TEST_DIR,    "#{model_name}_blueprint.rb"),  # Machinist Blueprints
             File.join(BLUEPRINTS_SPEC_DIR,    "#{model_name}_blueprint.rb"),  # Machinist Blueprints
             File.join(FACTORY_GIRL_TEST_DIR,  "#{model_name}_factory.rb"),    # Factory Girl Factories
             File.join(FACTORY_GIRL_SPEC_DIR,  "#{model_name}_factory.rb"),    # Factory Girl Factories
             File.join(FABRICATORS_TEST_DIR,   "#{model_name}_fabricator.rb"), # Fabrication Fabricators
             File.join(FABRICATORS_SPEC_DIR,   "#{model_name}_fabricator.rb"), # Fabrication Fabricators
            ].each do |file|
              remove_annotation_of_file(file) if File.exist?(file)
            end

          end
        rescue Exception => e
          puts "Unable to deannotate #{file}: #{e.message}"
          puts "\t" + e.backtrace.join("\n\t") if options[:trace]          
        end
      end
      puts "Removed annotation from: #{deannotated.join(', ')}"
    end

    def find_test_file(dir, file_name)
      Dir.glob(File.join(dir, "**", file_name)).first || File.join(dir, file_name)
    end
  end
end
