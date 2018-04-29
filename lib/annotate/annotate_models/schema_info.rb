module AnnotateModels
  module SchemaInfo
    class << self
      # Use the column information in an ActiveRecord class
      # to create a comment block containing a line for
      # each column. The line contains the column name,
      # the type (and length), and any optional attributes
      def generate(klass, header, options)
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

        cols = if ignore_columns = options[:ignore_columns]
                 klass.columns.reject do |col|
                   col.name.match(/#{ignore_columns}/)
                 end
               else
                 klass.columns
               end

        cols = cols.sort_by(&:name) if options[:sort]
        cols = classified_sort(cols) if options[:classified_sort]
        cols.each do |col|
          col_type = get_col_type(col)
          attrs = []
          attrs << "default(#{schema_default(klass, col)})" unless col.default.nil? || hide_default?(col_type, options)
          attrs << 'unsigned' if col.respond_to?(:unsigned?) && col.unsigned?
          attrs << 'not null' unless col.null
          attrs << 'primary key' if klass.primary_key && (klass.primary_key.is_a?(Array) ? klass.primary_key.collect(&:to_sym).include?(col.name.to_sym) : col.name.to_sym == klass.primary_key.to_sym)

          if col_type == 'decimal'
            col_type << "(#{col.precision}, #{col.scale})"
          elsif col_type != 'spatial'
            if col.limit
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
          elsif options[:format_markdown]
            name_remainder = max_size - col_name.length
            type_remainder = (md_type_allowance - 2) - col_type.length
            info << (sprintf("# **`%s`**%#{name_remainder}s | `%s`%#{type_remainder}s | `%s`", col_name, " ", col_type, " ", attrs.join(", ").rstrip)).gsub('``', '  ').rstrip + "\n"
          else
            info << sprintf("#  %-#{max_size}.#{max_size}s:%-#{bare_type_allowance}.#{bare_type_allowance}s %s", col_name, col_type, attrs.join(", ")).rstrip + "\n"
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

      private

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

      def max_schema_info_width(klass, options)
        if with_comments?(klass, options)
          max_size = klass.columns.map do |column|
            column.name.size + (column.comment ? column.comment.size : 0)
          end.max || 0
          max_size += 2
        else
          max_size = klass.column_names.map(&:size).max
        end
        max_size += options[:format_rdoc] ? 5 : 1

        max_size
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

      def get_col_type(col)
        if col.respond_to?(:bigint?) && col.bigint?
          'bigint'
        else
          (col.type || col.sql_type).to_s
        end
      end

      def schema_default(klass, column)
        quote(klass.column_defaults[column.name])
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

      def hide_default?(col_type, options)
        excludes =
          if options[:hide_default_column_types].blank?
            NO_DEFAULT_COL_TYPES
          else
            options[:hide_default_column_types].split(',')
          end

        excludes.include?(col_type)
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

      def retrieve_indexes_from_table(klass)
        table_name = klass.table_name
        return [] unless table_name

        indexes = klass.connection.indexes(table_name)
        return indexes if indexes.any? || !klass.table_name_prefix

        # Try to search the table without prefix
        table_name_without_prefix = table_name.to_s.sub(klass.table_name_prefix, '')
        klass.connection.indexes(table_name_without_prefix)
      end

      def with_comments?(klass, options)
        options[:with_comment] &&
          klass.columns.first.respond_to?(:comment) &&
          klass.columns.any? { |col| !col.comment.nil? }
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

      def index_columns_info(index)
        Array(index.columns).map do |col|
          if index.try(:orders) && index.orders[col.to_s]
            "#{col} #{index.orders[col.to_s].upcase}"
          else
            col.to_s.gsub("\r", '\r').gsub("\n", '\n')
          end
        end
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

        format_name = ->(fk) { options[:show_complete_foreign_keys] ? fk.name : fk.name.gsub(/(?<=^fk_rails_)[0-9a-f]{10}$/, '...') }

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
    end
  end
end
