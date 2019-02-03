require_relative './helpers'

module AnnotateRoutes
  # Class to remove annotations in routes.rb
  module RemovalProcessor
    class << self
      # @param routes_file [String]
      # @param existing_text [String]
      # @param options [Hash]
      def update(routes_file, existing_text, options)
        content, header_position = Helpers.strip_annotations(existing_text)
        new_content = strip_on_removal(content, header_position)
        new_text = new_content.join("\n")
        rewrite_contents(routes_file, existing_text, new_text, options)
      end

      private

      def strip_on_removal(content, header_position)
        case header_position
        when :before
          content.shift while content.first == ''
        when :after
          content.pop while content.last == ''
        end

        # Make sure we end on a trailing newline.
        content << '' unless content.last == ''

        # TODO: If the user buried it in the middle, we should probably see about
        # TODO: preserving a single line of space between the content above and
        # TODO: below...
        content
      end

      # @param routes_file [String]
      # @param existing_text [String]
      # @param new_text [String]
      # @param options [Hash]
      # @return [Boolean]
      def rewrite_contents(routes_file, existing_text, new_text, options)
        content_changed = existing_text != new_text
        frozen = options[:frozen]

        abort "annotate error. #{routes_file} needs to be updated, but annotate was run with `--frozen`." if content_changed && frozen

        if content_changed
          File.open(routes_file, 'wb') { |f| f.puts(new_text) }
          true
        else
          false
        end
      end
    end
  end
end
