require_relative './base_processor'

# This module provides methods for annotating config/routes.rb.
module AnnotateRoutes
  # This class provides methods for removing annotation from config/routes.rb.
  class RemovalProcessor < BaseProcessor
    # @return [Boolean]
    def update
      content, header_position = strip_annotations(existing_text)
      new_content = strip_on_removal(content, header_position)
      new_text = new_content.join("\n")
      rewrite_contents(new_text)
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
  end
end
