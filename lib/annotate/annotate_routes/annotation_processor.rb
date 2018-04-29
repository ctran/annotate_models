require_relative './base_processor'
require_relative './header_rows'

module AnnotateRoutes
  # AnnotationProcessor provides methods to add annotations to routes file.
  class AnnotationProcessor < BaseProcessor
    class << self
      # @param routes_file [String] path for routes_file
      # @param options [Hash] options
      def process(routes_file, options)
        routes_map = app_routes_map(options)
        header_rows = HeaderRows.generate(routes_map, options)

        new(routes_file, routes_map, header_rows).process(options)
      end

      private

      # @param options [Hash] options
      # @return [Array<String>]
      def app_routes_map(options)
        routes_map = `rake routes`.chomp("\n").split(/\n/, -1)

        # In old versions of Rake, the first line of output was the cwd.  Not so
        # much in newer ones.  We ditch that line if it exists, and if not, we
        # keep the line around.
        routes_map.shift if routes_map.first =~ %r{^\(in /}

        # Skip routes which match given regex
        # Note: it matches the complete line (route_name, path, controller/action)
        if options[:ignore_routes]
          routes_map.reject! { |line| line =~ /#{options[:ignore_routes]}/ }
        end

        routes_map
      end
    end

    # @param routes_file [String] path for routes_file
    # @param routes_map [Array <String>] result of `rake routes`
    # @param header_rows [Array <String>] header rows
    def initialize(routes_file, routes_map, header_rows)
      super(routes_file)
      @routes_map = routes_map
      @header_rows = header_rows
    end

    private

    attr_reader :header_rows

    # @param content [Array <String>]
    # @param header_position [Integer]
    # @param options [Hash]
    def new_text_rows(content, header_position, options)
      magic_comments_map, content = AnnotateRoutes.extract_magic_comments(content)
      if %w(before top).include?(options[:position_in_routes])
        header = header_rows << '' if content.first != ''
        magic_comments_map << '' if magic_comments_map.any?
        new_content = magic_comments_map + header + content
      else
        # Ensure we have adequate trailing newlines at the end of the file to
        # ensure a blank line separating the content from the annotation.
        content << '' unless content.last == ''

        # We're moving something from the top of the file to the bottom, so ditch
        # the spacer we put in the first time around.
        content.shift if header_position == :before && content.first == ''

        new_content = magic_comments_map + content + header_rows
      end

      new_content
    end
  end
end
