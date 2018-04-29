module AnnotateModels
  module SchemaInfo
    module IndexInfo
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
        def generate(index, max_size, options)
          if options[:format_markdown]
            final_index_string_in_markdown(index)
          else
            final_index_string(index, max_size)
          end
        end

        private

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
          return '' if value.blank?
          " #{INDEX_CLAUSES[:where][format]} #{value}"
        end

        def index_using_info(index, format = :default)
          value = index.try(:using) && index.using.try(:to_sym)
          return '' if value.blank?
          return '' if value == :btree
          " #{INDEX_CLAUSES[:using][format]} #{value}"
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
      end
    end
  end
end
