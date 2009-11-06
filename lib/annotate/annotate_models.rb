module AnnotateModels
  class << self
    # Annotate Models plugin use this header
    COMPAT_PREFIX = "== Schema Info"
    PREFIX = "== Schema Information"

    FIXTURE_DIRS = ["test/fixtures","spec/fixtures"]
    # File.join for windows reverse bar compat?
    # I dont use windows, can`t test
    UNIT_TEST_DIR     = File.join("test", "unit"  )
    SPEC_MODEL_DIR    = File.join("spec", "models")
    # Object Daddy http://github.com/flogic/object_daddy/tree/master
    EXEMPLARS_TEST_DIR     = File.join("test", "exemplars")
    EXEMPLARS_SPEC_DIR     = File.join("spec", "exemplars")
    # Machinist http://github.com/notahat/machinist
    BLUEPRINTS_DIR         = File.join("test", "blueprints")

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
      info = "# #{header}\n#\n"
      info << "# Table name: #{klass.table_name}\n#\n"

      max_size = klass.column_names.collect{|name| name.size}.max + 1
      klass.columns.each do |col|
        attrs = []
        attrs << "default(#{quote(col.default)})" unless col.default.nil?
        attrs << "not null" unless col.null
        attrs << "primary key" if col.name == klass.primary_key

        col_type = col.type.to_s
        if col_type == "decimal"
          col_type << "(#{col.precision}, #{col.scale})"
        else
          col_type << "(#{col.limit})" if col.limit
        end

        # Check out if we got a geometric column
        # and print the type and SRID
        if col.respond_to?(:geometry_type)
          attrs << "#{col.geometry_type}, #{col.srid}"
        end

        # Check if the column has indices and print "indexed" if true
        # If the indice include another colum, print it too.
        if options[:simple_indexes] # Check out if this column is indexed
          indices = klass.connection.indexes(klass.table_name)
          if indices = indices.select { |ind| ind.columns.include? col.name }
            indices.each do |ind|
              ind = ind.columns.reject! { |i| i == col.name }
              attrs << (ind.length == 0 ? "indexed" : "indexed => [#{ind.join(", ")}]")
            end
          end
        end

        info << sprintf("#  %-#{max_size}.#{max_size}s:%-15.15s %s", col.name, col_type, attrs.join(", ")).rstrip + "\n"
      end

      if options[:show_indexes]
        info << get_index_info(klass)
      end

      info << "#\n\n"
    end

    def get_index_info(klass)
      index_info = "#\n# Indexes\n#\n"

      indexes = klass.connection.indexes(klass.table_name)
      return "" if indexes.empty?

      max_size = indexes.collect{|index| index.name.size}.max + 1
      indexes.each do |index|
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
    #                      "before" or "after". Default is "before".
    #  :position_in_class<Symbol>:: where to place the annotated section in model file
    #  :position_in_fixture<Symbol>:: where to place the annotated section in fixture file
    #  :position_in_others<Symbol>:: where to place the annotated section in the rest of
    #                      supported files
    #
    def annotate_one_file(file_name, info_block, options={})
      if File.exist?(file_name)
        old_content = File.read(file_name)

        # Ignore the Schema version line because it changes with each migration
        header = Regexp.new(/(^# Table name:.*?\n(#.*\n)*\n)/)
        old_header = old_content.match(header).to_s
        new_header = info_block.match(header).to_s

        if old_header == new_header
          false
        else
          # Remove old schema info
          old_content.sub!(/^# #{COMPAT_PREFIX}.*?\n(#.*\n)*\n/, '')

          # Write it back
          new_content = options[:position] == 'before' ?  (info_block + old_content) : (old_content + "\n" + info_block)

          File.open(file_name, "wb") { |f| f.puts new_content }
          true
        end
      end
    end

    def remove_annotation_of_file(file_name)
      if File.exist?(file_name)
        content = File.read(file_name)

        content.sub!(/^# #{COMPAT_PREFIX}.*?\n(#.*\n)*\n/, '')

        File.open(file_name, "wb") { |f| f.puts content }
      end
    end

    # Given the name of an ActiveRecord class, create a schema
    # info block (basically a comment containing information
    # on the columns and their types) and put it at the front
    # of the model and fixture source files.
    # Returns true or false depending on whether the source
    # files were modified.
    def annotate(klass, file, header,options={})
      info = get_schema_info(klass, header, options)
      annotated = false
      model_name = klass.name.underscore
      model_file_name = File.join(model_dir, file)

      if annotate_one_file(model_file_name, info, options_with_position(options, :position_in_class))
        annotated = true
      end
 
      unless ENV['exclude_tests']
        [
          File.join(UNIT_TEST_DIR,      "#{model_name}_test.rb"), # test
          File.join(SPEC_MODEL_DIR,     "#{model_name}_spec.rb"), # spec
        ].each do |file| 
          # todo: add an option "position_in_test" -- or maybe just ask if anyone ever wants different positions for model vs. test vs. fixture
          annotate_one_file(file, info, options_with_position(options, :position_in_fixture))
        end
      end

      unless ENV['exclude_fixtures']
        [
        File.join(EXEMPLARS_TEST_DIR, "#{model_name}_exemplar.rb"),  # Object Daddy
        File.join(EXEMPLARS_SPEC_DIR, "#{model_name}_exemplar.rb"),  # Object Daddy
        File.join(BLUEPRINTS_DIR,     "#{model_name}_blueprint.rb"), # Machinist Blueprints
        ].each do |file| 
          annotate_one_file(file, info, options_with_position(options, :position_in_fixture))
        end

        FIXTURE_DIRS.each do |dir|
          fixture_file_name = File.join(dir,klass.table_name + ".yml")
          if File.exist?(fixture_file_name)
            annotate_one_file(fixture_file_name, info, options_with_position(options, :position_in_fixture))         
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
    def get_model_files
      models = ARGV.dup
      models.shift
      models.reject!{|m| m.match(/^(.*)=/)}
      if models.empty?
        begin
          Dir.chdir(model_dir) do
            models = Dir["**/*.rb"]
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
      require File.expand_path("#{model_dir}/#{file}") # this is for non-rails projects, which don't get Rails auto-require magic
      model = file.gsub(/\.rb$/, '').camelize
      parts = model.split('::')
      begin
        parts.inject(Object) {|klass, part| klass.const_get(part) }
      rescue LoadError, NameError
        Object.const_get(parts.last)
      end
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

      header = PREFIX.dup

      if options[:include_version]
        version = ActiveRecord::Migrator.current_version rescue 0
        if version > 0
          header << "\n# Schema version: #{version}"
        end
      end

      if options[:model_dir]
        self.model_dir = options[:model_dir]
      end

      annotated = []
      get_model_files.each do |file|
        begin
          klass = get_model_class(file)
          if klass < ActiveRecord::Base && !klass.abstract_class?
            if annotate(klass, file, header, options)
              annotated << klass
            end
          end
        rescue Exception => e
          puts "Unable to annotate #{file}: #{e.inspect}"
          puts ""
# todo: check if all backtrace lines are in "gems" -- if so, it's an annotate bug, so print the whole stack trace.
#          puts e.backtrace.join("\n\t")  
        end
      end
      if annotated.empty?
        puts "Nothing annotated."
      else
        puts "Annotated (#{annotated.length}): #{annotated.join(', ')}"
      end
    end

    def remove_annotations(options={})
      if options[:model_dir]
        puts "removing"
        self.model_dir = options[:model_dir]
      end
      deannotated = []
      get_model_files.each do |file|
        begin
          klass = get_model_class(file)
          if klass < ActiveRecord::Base && !klass.abstract_class?
            deannotated << klass

            model_file_name = File.join(model_dir, file)
            remove_annotation_of_file(model_file_name)

            FIXTURE_DIRS.each do |dir|
              fixture_file_name = File.join(dir,klass.table_name + ".yml")
              remove_annotation_of_file(fixture_file_name) if File.exist?(fixture_file_name)
            end
            
            [ File.join(UNIT_TEST_DIR, "#{klass.name.underscore}_test.rb"),
              File.join(SPEC_MODEL_DIR,"#{klass.name.underscore}_spec.rb")].each do |file|
              remove_annotation_of_file(file) if File.exist?(file)
            end
            
          end
        rescue Exception => e
          puts "Unable to annotate #{file}: #{e.message}"
        end
      end
      puts "Removed annotation from: #{deannotated.join(', ')}"
    end
  end
end

# monkey patches

module ::ActiveRecord
  class Base
    def self.method_missing(name, *args)
      # ignore this, so unknown/unloaded macros won't cause parsing to fail
    end
  end
end
