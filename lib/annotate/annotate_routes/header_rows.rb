module AnnotateRoutes
  module HeaderRows
    PREFIX = '== Route Map'.freeze
    PREFIX_MD = '## Route Map'.freeze

    HEADER_ROW = ['Prefix', 'Verb', 'URI Pattern', 'Controller#Action'].freeze

    class << self
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

        maxs = [HEADER_ROW.map(&:size)] + routes_map[1..-1].map { |line| line.split.map(&:size) }

        if options[:format_markdown]
          max = maxs.map(&:max).compact.max

          out << comment(content(HEADER_ROW, maxs, options))
          out << comment(content(['-' * max, '-' * max, '-' * max, '-' * max], maxs, options))
        else
          out << comment(content(routes_map[0], maxs, options))
        end

        out += routes_map[1..-1].map { |line| comment(content(route(line, options), maxs, options)) }
        out << comment(options[:wrapper_close]) if options[:wrapper_close]

        out
      end

      private

      def comment(line = nil)
        return '#' if line.blank?
        "# #{line}"
      end

      def prefix(options)
        options[:format_markdown] ? PREFIX_MD : PREFIX
      end

      def timestamp(options)
        options[:timestamp] ? " (Updated #{Time.now.strftime('%Y-%m-%d %H:%M')})" : ''
      end

      def route(line, options)
        options[:format_markdown] ? line.split(' ') : line
      end

      def content(line, maxs, options = {})
        return line.rstrip unless options[:format_markdown]

        line.each_with_index.map do |elem, index|
          min_length = maxs.map { |arr| arr[index] }.max || 0

          sprintf("%-#{min_length}.#{min_length}s", elem.tr('|', '-'))
        end.join(' | ')
      end
    end
  end
end
