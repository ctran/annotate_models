module AnnotateRoutes
  # HeaderRows generates of header rows in annotation
  module HeaderRows
    PREFIX = '== Route Map'.freeze
    PREFIX_MD = '## Route Map'.freeze

    HEADER_ROW = ['Prefix', 'Verb', 'URI Pattern', 'Controller#Action'].freeze

    class << self
      # @param routes_map [Array <String>] result of `rake routes`
      # @param options [Hash] options
      # @return [Array <String>]
      def generate(routes_map, options = {})
        magic_comments_map, routes_map = AnnotateRoutes.extract_magic_comments(routes_map)

        out = []

        magic_comments_map.each do |magic_comment|
          out << magic_comment
        end
        out << '' if magic_comments_map.any?

        out << comment(options[:wrapper_open]) if options[:wrapper_open]

        out << comment("#{prefix(options)}#{timestamp(options)}")
        out << comment

        return out if routes_map.size.zero?

        if options[:format_markdown]
          maxs = [HEADER_ROW.map(&:size)] + routes_map[1..-1].map { |line| line.split.map(&:size) }
          max = maxs.map(&:max).compact.max

          out << comment(markdown_content(HEADER_ROW, maxs))
          out << comment(markdown_content(Array.new(4) { '-' * max }, maxs))
          out += routes_map[1..-1].map { |line| comment(markdown_content(line.split(' '), maxs)) }
        else
          out += routes_map.map { |line| comment(line.rstrip) }
        end

        out << comment(options[:wrapper_close]) if options[:wrapper_close]

        out
      end

      private

      # @param line [String]
      # @return [String]
      def comment(line = nil)
        return '#' if line.blank?
        "# #{line}"
      end

      # @param options [Hash]
      # @return [String]
      def prefix(options)
        options[:format_markdown] ? PREFIX_MD : PREFIX
      end

      # @param options [Hash]
      # @return [String]
      def timestamp(options)
        options[:timestamp] ? " (Updated #{Time.now.strftime('%Y-%m-%d %H:%M')})" : ''
      end

      # @param line_splited [Array <String>]
      # @param maxs [Array <Integer>]
      # @return [String]
      def markdown_content(line_splited, maxs)
        line_splited.each_with_index
                    .map { |elm, i| format_markdown_row(elm, maxs, i) }
                    .join(' | ')
      end

      # @param elm [String]
      # @param maxs [Array <Integer>]
      # @param i [Integer]
      # @return [String]
      def format_markdown_row(elm, maxs, i)
        min_length = maxs.map { |arr| arr[i] }.max || 0
        format("%-#{min_length}.#{min_length}s",
               elm.tr('|', '-'))
      end
    end
  end
end
