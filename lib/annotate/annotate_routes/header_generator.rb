require_relative './helpers'

module AnnotateRoutes
  class HeaderGenerator
    class << self
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
    end
  end
end
