module Annotate
  # Class for holding helper methods. Done to make lib/annotate.rb less bloated.
  class Helpers
    class << self
      def skip_on_migration?
        ENV.fetch('ANNOTATE_SKIP_ON_DB_MIGRATE', nil) =~ Constants::TRUE_RE || ENV.fetch('skip_on_db_migrate', nil) =~ Constants::TRUE_RE
      end

      def include_routes?
        ENV.fetch('routes', nil) =~ Constants::TRUE_RE
      end

      def include_models?
        ENV.fetch('models', nil) =~ Constants::TRUE_RE
      end

      def true?(val)
        val.present? && Constants::TRUE_RE.match?(val)
      end

      def fallback(*args)
        args.detect(&:present?)
      end

      def reset_options(options)
        options.flatten.each { |key| ENV[key.to_s] = nil }
      end
    end
  end
end
