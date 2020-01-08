require_relative './helpers'

module AnnotateRoutes
  class HeaderGenerator
    PREFIX = '== Route Map'.freeze
    PREFIX_MD = '## Route Map'.freeze
    HEADER_ROW = ['Prefix', 'Verb', 'URI Pattern', 'Controller#Action'].freeze

    class << self
      def generate(options = {})
        routes_map = app_routes_map(options)

        magic_comments_map, routes_map = Helpers.extract_magic_comments_from_array(routes_map)

        out = []

        magic_comments_map.each do |magic_comment|
          out << magic_comment
        end
        out << '' if magic_comments_map.any?

        out << comment(options[:wrapper_open]) if options[:wrapper_open]

        out << comment(options[:format_markdown] ? PREFIX_MD : PREFIX) + (options[:timestamp] ? " (Updated #{Time.now.strftime('%Y-%m-%d %H:%M')})" : '')
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

        out += routes_map[1..-1].map { |line| comment(content(options[:format_markdown] ? line.split(' ') : line, maxs, options)) }
        out << comment(options[:wrapper_close]) if options[:wrapper_close]

        out
      end

      private

      def app_routes_map(options)
        routes_map = `rake routes`.chomp("\n").split(/\n/, -1)

        # In old versions of Rake, the first line of output was the cwd.  Not so
        # much in newer ones.  We ditch that line if it exists, and if not, we
        # keep the line around.
        routes_map.shift if routes_map.first =~ /^\(in \//

        # Skip routes which match given regex
        # Note: it matches the complete line (route_name, path, controller/action)
        if options[:ignore_routes]
          routes_map.reject! { |line| line =~ /#{options[:ignore_routes]}/ }
        end

        routes_map
      end

      def comment(row = '')
        if row == ''
          '#'
        else
          "# #{row}"
        end
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
