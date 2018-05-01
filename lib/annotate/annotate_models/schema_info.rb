# rubocop:disable  Metrics/ModuleLength

require_relative './schema_info/col_info'
require_relative './schema_info/index_info'

module AnnotateModels
  # This module provides module method to get schema info.
  module SchemaInfo
    MD_NAMES_OVERHEAD = 6
    MD_TYPE_ALLOWANCE = 18
    BARE_TYPE_ALLOWANCE = 16

    class << self
      # Use the column information in an ActiveRecord class
      # to create a comment block containing a line for
      # each column. The line contains the column name,
      # the type (and length), and any optional attributes
      def generate(klass, header, options)
        info = "# #{header}\n"
        info << get_schema_header_text(klass, options)

        max_size = max_schema_info_width(klass, options)

        if options[:format_markdown]
          info << markdown_table_header(max_size)
          info << markdown_table_header_end_line(max_size)
        end

        cols = get_cols(klass, options)
        indices = retrieve_indexes_from_table(klass)
        cols.each do |col|
          info << ColInfo.generate(klass, options, max_size, col, indices)
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

      def markdown_table_header(max_size)
        format("# %-#{max_size + MD_NAMES_OVERHEAD}.#{max_size + MD_NAMES_OVERHEAD}s | %-#{MD_TYPE_ALLOWANCE}.#{MD_TYPE_ALLOWANCE}s | %s\n",
               'Name',
               'Type',
               'Attributes')
      end

      def markdown_table_header_end_line(max_size)
        "# #{'-' * (max_size + MD_NAMES_OVERHEAD)} | #{'-' * MD_TYPE_ALLOWANCE} | #{'-' * 27}\n"
      end

      def get_cols(klass, options)
        ignore_columns = options[:ignore_columns]

        cols = if ignore_columns
                 klass.columns.reject do |col|
                   col.name.match(/#{ignore_columns}/)
                 end
               else
                 klass.columns
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

        max_size = indexes.collect { |index| index.name.size }.max + 1
        indexes.sort_by(&:name).each do |index|
          index_info << IndexInfo.generate(index, max_size, options)
        end

        index_info
      end

      def get_foreign_key_info(klass, options = {})
        return '' unless foreign_keys?(klass)

        fk_info = if options[:format_markdown]
                    "#\n# ### Foreign Keys\n#\n"
                  else
                    "#\n# Foreign Keys\n#\n"
                  end

        format_name = ->(fk) { options[:show_complete_foreign_keys] ? fk.name : fk.name.gsub(/(?<=^fk_rails_)[0-9a-f]{10}$/, '...') }

        foreign_keys = klass.connection.foreign_keys(klass.table_name)
        max_size = foreign_keys.map(&format_name).map(&:size).max + 1
        foreign_keys.sort_by { |fk| [format_name.call(fk), fk.column] }.each do |fk|
          ref_info = "#{fk.column} => #{fk.to_table}.#{fk.primary_key}"
          constraints_info = ''
          constraints_info += "ON DELETE => #{fk.on_delete} " if fk.on_delete
          constraints_info += "ON UPDATE => #{fk.on_update} " if fk.on_update
          constraints_info.strip!

          fk_info << if options[:format_markdown]
                       format("# * `%s`%s:\n#     * **`%s`**\n", format_name.call(fk), constraints_info.blank? ? '' : " (_#{constraints_info}_)", ref_info)
                     else
                       format("#  %-#{max_size}.#{max_size}s %s %s", format_name.call(fk), "(#{ref_info})", constraints_info).rstrip + "\n"
                     end
        end

        fk_info
      end

      def foreign_keys?(klass)
        return false unless klass.connection.respond_to?(:supports_foreign_keys?)
        return false unless klass.connection.supports_foreign_keys?
        return false unless klass.connection.respond_to?(:foreign_keys)

        foreign_keys = klass.connection.foreign_keys(klass.table_name)
        return false if foreign_keys.empty?
        true
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
