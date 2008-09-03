module AnnotateModels
  class << self
    MODEL_DIR   = "app/models"
    FIXTURE_DIRS = ["test/fixtures","spec/fixtures"]
    PREFIX = "== Schema Information"

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
    def get_schema_info(klass, header)
      info = "# #{header}\n#\n"
      info << "# Table name: #{klass.table_name}\n#\n"

      max_size = klass.column_names.collect{|name| name.size}.max + 1
      klass.columns.each do |col|
        attrs = []
        attrs << "default(#{quote(col.default)})" if col.default
        attrs << "not null" unless col.null
        attrs << "primary key" if col.name == klass.primary_key

        col_type = col.type.to_s
        if col_type == "decimal"
          col_type << "(#{col.precision}, #{col.scale})"
        else
          col_type << "(#{col.limit})" if col.limit
        end
        info << sprintf("#  %-#{max_size}.#{max_size}s:%-15.15s %s", col.name, col_type, attrs.join(", ")).rstrip + "\n"
      end

      info << "#\n\n"
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
          old_content.sub!(/^# #{PREFIX}.*?\n(#.*\n)*\n/, '')

          # Write it back
          new_content = options[:position] == "after" ? (old_content + "\n" + info_block) : (info_block + old_content)

          File.open(file_name, "w") { |f| f.puts new_content }
          true
        end
      end
    end
    
    def remove_annotation_of_file(file_name)
      if File.exist?(file_name)
        content = File.read(file_name)

        content.sub!(/^# #{PREFIX}.*?\n(#.*\n)*\n/, '')
        
        File.open(file_name, "w") { |f| f.puts content }
      end
    end

    # Given the name of an ActiveRecord class, create a schema
    # info block (basically a comment containing information
    # on the columns and their types) and put it at the front
    # of the model and fixture source files.
    # Returns true or false depending on whether the source
    # files were modified.

    def annotate(klass, file, header,options={})
      info = get_schema_info(klass, header)
      annotated = false

      model_file_name = File.join(MODEL_DIR, file)
      if annotate_one_file(model_file_name, info, options.merge(:position=>(options[:position_in_class] || options[:position])))
        annotated = true
      end

      FIXTURE_DIRS.each do |dir|
        fixture_file_name = File.join(dir,klass.table_name + ".yml")
        annotate_one_file(fixture_file_name, info, options.merge(:position=>(options[:position_in_fixture] || options[:position]))) if File.exist?(fixture_file_name)
      end
      annotated
    end

    # Return a list of the model files to annotate. If we have
    # command line arguments, they're assumed to be either
    # the underscore or CamelCase versions of model names.
    # Otherwise we take all the model files in the
    # app/models directory.
    def get_model_files
      models = ARGV.dup
      models.shift
      models.reject!{|m| m.starts_with?("position=")}
      if models.empty?
        Dir.chdir(MODEL_DIR) do
          models = Dir["**/*.rb"]
        end
      end
      models
    end
  
    # Retrieve the classes belonging to the model names we're asked to process
    # Check for namespaced models in subdirectories as well as models
    # in subdirectories without namespacing.
    def get_model_class(file)
      model = file.gsub(/\.rb$/, '').camelize
      parts = model.split('::')
      begin
        parts.inject(Object) {|klass, part| klass.const_get(part) }
      rescue LoadError
        Object.const_get(parts.last)
      end
    end

    # We're passed a name of things that might be
    # ActiveRecord models. If we can find the class, and
    # if its a subclass of ActiveRecord::Base,
    # then pas it to the associated block
    def do_annotations(options={})
      header = PREFIX.dup
      version = ActiveRecord::Migrator.current_version rescue 0
      if version > 0
        header << "\n# Schema version: #{version}"
      end

      annotated = []
      get_model_files.each do |file|
        begin
          klass = get_model_class(file)
          if klass < ActiveRecord::Base && !klass.abstract_class?
            if annotate(klass, file, header,options)
              annotated << klass
            end
          end
        rescue Exception => e
          puts "Unable to annotate #{file}: #{e.message}"
        end
      end
      if annotated.empty?
        puts "Nothing annotated!"
      else
        puts "Annotated #{annotated.join(', ')}"
      end
    end
    
    def remove_annotations
      deannotated = []
      get_model_files.each do |file|
        begin
          klass = get_model_class(file)
          if klass < ActiveRecord::Base && !klass.abstract_class?
            deannotated << klass
            
            model_file_name = File.join(MODEL_DIR, file)
            remove_annotation_of_file(model_file_name)
            
            FIXTURE_DIRS.each do |dir|
              fixture_file_name = File.join(dir,klass.table_name + ".yml")
              remove_annotation_of_file(fixture_file_name) if File.exist?(fixture_file_name)
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