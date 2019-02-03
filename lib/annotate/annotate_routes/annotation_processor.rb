require_relative './base_processor'
require_relative './helpers'
require_relative './header_generator'

module AnnotateRoutes
  # Class to add and update annotations in routes.rb
  class AnnotationProcessor < BaseProcessor
    # @return [Boolean]
    def update
      header = HeaderGenerator.generate(options)
      content, header_position = Helpers.strip_annotations(existing_text)
      new_content = annotate_routes(header, content, header_position)
      new_text = new_content.join("\n")
      rewrite_contents(new_text)
    end

    private

    def annotate_routes(header, content, header_position)
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
  end
end
