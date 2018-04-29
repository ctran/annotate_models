require_relative './base_processor'

module AnnotateRoutes
  # AnnotationProcessor provides methods to remove annotations from routes file.
  class RemoveProcessor < BaseProcessor
    class << self
      # @param routes_file [String] path for routes_file
      # @param options [Hash] options
      def process(routes_file, options = {})
        new(routes_file).process(options)
      end
    end

    private

    # @param content [Array <String>]
    # @param header_position [Integer]
    # @param options [Hash]
    def new_text_rows(content, header_position, _options)
      if header_position == :before
        content.shift while content.first == ''
      elsif header_position == :after
        content.pop while content.last == ''
      end

      # TODO: If the user buried it in the middle, we should probably see about
      # TODO: preserving a single line of space between the content above and
      # TODO: below...
      content
    end
  end
end
