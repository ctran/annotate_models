require_relative './helpers'
require_relative './header_generator'

# This module provides methods for annotating config/routes.rb.
module AnnotateRoutes
  # This module provides methods for adding annotation to config/routes.rb.
  module AnnotationProcessor
    class << self
      # @param [Boolean]
      def update(routes_file, existing_text, options = {})
        header = HeaderGenerator.generate(options)
        content, header_position = Helpers.strip_annotations(existing_text)
        new_content = annotate_routes(header, content, header_position, options)
        new_text = new_content.join("\n")
        rewrite_contents(routes_file, existing_text, new_text, options)
      end

      private

      def annotate_routes(header, content, header_position, options = {})
        magic_comments_map, content = Helpers.extract_magic_comments_from_array(content)
        if %w[before top].include?(options[:position_in_routes])
          header = header << '' if content.first != ''
          magic_comments_map << '' if magic_comments_map.any?
          new_content = magic_comments_map + header + content
        else
          # Ensure we have adequate trailing newlines at the end of the file to
          # ensure a blank line separating the content from the annotation.
          content << '' unless content.last == ''

          # We're moving something from the top of the file to the bottom, so ditch
          # the spacer we put in the first time around.
          content.shift if header_position == :before && content.first == ''

          new_content = magic_comments_map + content + header
        end

        # Make sure we end on a trailing newline.
        new_content << '' unless new_content.last == ''

        new_content
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
