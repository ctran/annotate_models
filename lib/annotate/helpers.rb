module Annotate
  # Class for holding helper methods. Done to make lib/annotate.rb less bloated.
  class Helpers
    class << self
      def skip_on_migration?
        ENV['ANNOTATE_SKIP_ON_DB_MIGRATE'] =~ Constants::TRUE_RE || ENV['skip_on_db_migrate'] =~ Constants::TRUE_RE
      end

      def include_routes?
        ENV['routes'] =~ Constants::TRUE_RE
      end

      def include_models?
        ENV['models'] =~ Constants::TRUE_RE
      end
    end
  end
end
