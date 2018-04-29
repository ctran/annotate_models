module AnnotateModels
  class ModelClass
    class ForeignKey
      def initialize(foreign_key)
        @foreign_key = foreign_key
      end

      def format_name(options)
        options[:show_complete_foreign_keys] ? name : name.gsub(/(?<=^fk_rails_)[0-9a-f]{10}$/, '...')
      end

      def to_a(options)
        [format_name(options), column]
      end

      def to_s(max_size, options)
        ref_info = "#{column} => #{to_table}.#{primary_key}"

        constraints_info = ''
        constraints_info << "ON DELETE => #{on_delete} " if on_delete
        constraints_info << "ON UPDATE => #{on_update} " if on_update
        constraints_info.strip!

        if options[:format_markdown]
          sprintf("# * `%s`%s:\n#     * **`%s`**\n",
                  format_name(options),
                  constraints_info.blank? ? '' : " (_#{constraints_info}_)",
                  ref_info)
         else
          sprintf("#  %-#{max_size}.#{max_size}s %s %s",
                  format_name(options),
                  "(#{ref_info})",
                  constraints_info).rstrip + "\n"
         end
      end

      private

      def name
        @foreign_key.name
      end

      def column
        @foreign_key.column
      end

      def to_table
        @foreign_key.to_table
      end

      def primary_key
        @foreign_key.primary_key
      end

      def on_delete
        @foreign_key.on_delete
      end

      def on_update
        @foreign_key.on_update
      end
    end
  end
end
