module AnnotateModels
  # This class provides method to get schema info.
  class ModelClass
    MD_NAMES_OVERHEAD = 6
    MD_TYPE_ALLOWANCE = 18

    def initialize(klass)
      @klass = klass
    end

    # Use the column information in an ActiveRecord class
    # to create a comment block containing a line for
    # each column. The line contains the column name,
    # the type (and length), and any optional attributes
    def to_s(header, options = {})
      str = "# #{header}\n"
      str << get_schema_header_text(options)

      max_size = max_schema_info_width(options)

      if options[:format_markdown]
        str << markdown_table_header(max_size)
        str << markdown_table_header_end_line(max_size)
      end

      cols = get_cols(options)
      cols.each do |col|
        wrapped_col = Col.new(col, self)
        str << wrapped_col.to_s(max_size, options)
      end

      if options[:show_indexes] && table_exists?
        str << get_index_info(options)
      end

      if options[:show_foreign_keys] && table_exists?
        str << get_foreign_key_info(options)
      end

      str << get_schema_footer_text(options)
      str
    end

    def model_name
      @klass.name.underscore
    end

    def table_name
      @klass.table_name
    end

    def column_defaults(name)
      @klass.column_defaults[name]
    end

    def indexes_from_table
      @indexes_from_table ||=
        if table_name
          indexes = connection.indexes(table_name)
          if indexes.any? || !table_name_prefix
            indexes
          else
            # Try to search the table without prefix
            connection.indexes(table_name_without_prefix)
          end
        else
          []
        end
    end

    def primary_key
      @klass.primary_key
    end

    alias primary_key? primary_key

    def columns
      @klass.columns
    end

    def table_exists?
      @klass.table_exists?
    end

    private

    def column_names
      @klass.column_names
    end

    def connection
      @klass.connection
    end

    def table_name_prefix
      @klass.table_name_prefix
    end

    def table_name_without_prefix
      @table_name_without_prefix ||= table_name.to_s.sub(table_name_prefix, '')
    end

    def foreign_keys
      @foreign_keys ||= connection.foreign_keys(table_name)
    end

    def get_schema_header_text(options = {})
      str = "#\n"
      if options[:format_markdown]
        str << "# Table name: `#{table_name}`\n"
        str << "#\n"
        str << "# ### Columns\n"
      else
        str << "# Table name: #{table_name}\n"
      end
      str << "#\n"
    end

    def max_schema_info_width(options)
      if with_comments?(options)
        max_size = columns.map { |column|
          column.name.size + (column.comment ? column.comment.size : 0)
        }.max || 0
        max_size += 2
      else
        max_size = column_names.map(&:size).max
      end
      max_size += options[:format_rdoc] ? 5 : 1

      max_size
    end

    def with_comments?(options)
      options[:with_comment] &&
        columns.first.respond_to?(:comment) &&
        columns.any? { |col| !col.comment.nil? }
    end

    def markdown_table_header(max_size)
      sprintf("# %-#{max_size + MD_NAMES_OVERHEAD}.#{max_size + MD_NAMES_OVERHEAD}s | %-#{MD_TYPE_ALLOWANCE}.#{MD_TYPE_ALLOWANCE}s | %s\n",
              'Name',
              'Type',
              'Attributes')
    end

    def markdown_table_header_end_line(max_size)
      "# #{'-' * (max_size + MD_NAMES_OVERHEAD)} | #{'-' * MD_TYPE_ALLOWANCE} | #{'-' * 27}\n"
    end

    def get_cols(options)
      ignore_columns = options[:ignore_columns]

      cols = if ignore_columns
               columns.reject do |col|
                 col.name.match(/#{ignore_columns}/)
               end
             else
               columns
             end

      cols = cols.sort_by(&:name) if options[:sort]
      cols = classified_sort(cols) if options[:classified_sort]
      cols
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

    def get_index_info(options = {})
      index_info = if options[:format_markdown]
                     "#\n# ### Indexes\n#\n"
                   else
                     "#\n# Indexes\n#\n"
                   end

      return '' if indexes_from_table.empty?

      max_size = indexes_from_table.collect { |index| index.name.size }.max + 1
      indexes_from_table.sort_by(&:name).each do |index|
        wrapped_index = Index.new(index)
        index_info << wrapped_index.to_s(max_size, options)
      end

      index_info
    end

    def get_foreign_key_info(options = {})
      return '' unless foreign_keys?

      fk_info = if options[:format_markdown]
                  "#\n# ### Foreign Keys\n#\n"
                else
                  "#\n# Foreign Keys\n#\n"
                end

      wrapped_foreign_keys = foreign_keys.map { |foreign_key| ForeignKey.new(foreign_key) }
      max_size = wrapped_foreign_keys.map { |wrapped_foreign_key | wrapped_foreign_key.format_name(options) }.map(&:length).max + 1
      fk_info << wrapped_foreign_keys
        .sort_by { |wrapped_foreign_key | wrapped_foreign_key.to_a(options) }
        .map { |wrapped_foreign_key | wrapped_foreign_key.to_s(max_size, options) }
        .join

      fk_info
    end

    def foreign_keys?
      return false unless connection.respond_to?(:supports_foreign_keys?)
      return false unless connection.supports_foreign_keys?
      return false unless connection.respond_to?(:foreign_keys)

      return false if foreign_keys.empty?
      true
    end

    def get_schema_footer_text(options = {})
      str = ''
      if options[:format_rdoc]
        str << "#--\n"
        str << "# #{END_MARK}\n"
        str << "#++\n"
      else
        str << "#\n"
      end
      str
    end
  end
end

require_relative './model_class/col'
require_relative './model_class/index'
require_relative './model_class/foreign_key'
