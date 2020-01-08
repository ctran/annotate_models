require_relative './base_processor'
require_relative './header_generator'
require_relative './magic_comments_extractor'

# This module provides methods for annotating config/routes.rb.
module AnnotateRoutes
  # This class provides methods for adding annotation to config/routes.rb.
  class AnnotationProcessor < BaseProcessor
    private

    def generate_new_content_array(content, header_position)
      header = HeaderGenerator.generate(options)
      magic_comments_map, content = MagicCommentsExtractor.execute(content)
      if %w[before top].include?(options[:position_in_routes])
        new_content_array = []
        new_content_array += magic_comments_map
        new_content_array << '' if magic_comments_map.any?
        new_content_array += header
        new_content_array << '' if content.first != ''
        new_content_array += content
      else
        # Ensure we have adequate trailing newlines at the end of the file to
        # ensure a blank line separating the content from the annotation.
        content << '' unless content.last == ''

        # We're moving something from the top of the file to the bottom, so ditch
        # the spacer we put in the first time around.
        content.shift if header_position == :before && content.first == ''

        new_content_array = magic_comments_map + content + header
      end

      # Make sure we end on a trailing newline.
      new_content_array << '' unless new_content_array.last == ''

      new_content_array
    end
  end
end
