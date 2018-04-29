module AnnotateModels
  module SchemaInfo
    module ColInfo
      # Don't show limit (#) on these column types
      # Example: show "integer" instead of "integer(4)"
      NO_LIMIT_COL_TYPES = %w(integer boolean).freeze

      # Don't show default value for these column types
      NO_DEFAULT_COL_TYPES = %w(json jsonb hstore).freeze

      class << self
        def generate(klass, options, max_size, col, indices)
          col_type = get_col_type(col)
          attrs = []
          attrs << "default(#{schema_default(klass, col)})" if mark_as_default?(col, col_type, options)
          attrs << 'unsigned' if col.respond_to?(:unsigned?) && col.unsigned?
          attrs << 'not null' unless col.null
          attrs << 'primary key' if primary_key?(klass, col)

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
          if options[:simple_indexes] && klass.table_exists? # Check out if this column is indexed
            if indices
              indices.select { |ind| ind.columns.include? col.name }.sort_by(&:name).each do |ind|
                next if ind.columns.is_a?(String)
                ind = ind.columns.reject! { |i| i == col.name }
                attrs << (ind.empty? ? "indexed" : "indexed => [#{ind.join(", ")}]")
              end
            end
          end

          get_col_info(klass, options, col, col_type, attrs, max_size)
        end

        private

        def get_col_type(col)
          if col.respond_to?(:bigint?) && col.bigint?
            'bigint'
          else
            (col.type || col.sql_type).to_s
          end
        end

        def mark_as_default?(col, col_type, options)
          !col.default.nil? && !hide_default?(col_type, options)
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

        def primary_key?(klass, col)
          return false unless klass.primary_key

          if klass.primary_key.is_a?(Array)
            klass.primary_key.collect(&:to_sym).include?(col.name.to_sym)
          else
            col.name.to_sym == klass.primary_key.to_sym
          end
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

        def get_col_info(klass, options, col, col_type, attrs, max_size)
          col_name = get_col_name(klass, options, col)
          base_text = if options[:format_rdoc]
                        sprintf("# %-#{max_size}.#{max_size}s<tt>%s</tt>", "*#{col_name}*::",
                                attrs.unshift(col_type).join(', '))
                      elsif options[:format_markdown]
                        name_remainder = max_size - col_name.length
                        type_remainder = (MD_TYPE_ALLOWANCE - 2) - col_type.length
                        sprintf("# **`%s`**%#{name_remainder}s | `%s`%#{type_remainder}s | `%s`",
                                col_name,
                                " ",
                                col_type,
                                " ",
                                attrs.join(", ").rstrip).gsub('``', '  ')
                      else
                        sprintf("#  %-#{max_size}.#{max_size}s:%-#{BARE_TYPE_ALLOWANCE}.#{BARE_TYPE_ALLOWANCE}s %s",
                                col_name,
                                col_type,
                                attrs.join(", "))
                      end
          "#{base_text.rstrip}\n"
        end

        def get_col_name(klass, options, col)
          if with_comments?(klass, options, col)
            "#{col.name}(#{col.comment})"
          else
            col.name
          end
        end

        def with_comments?(klass, options, col)
          options[:with_comment] &&
            klass.columns.first.respond_to?(:comment) &&
            klass.columns.any? { |col| !col.comment.nil? } &&
            col.comment
        end
      end
    end
  end
end
