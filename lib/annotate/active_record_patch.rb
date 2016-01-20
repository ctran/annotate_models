# monkey patches

class Object
  module ActiveRecord
    # Ignore unknown/unloaded macros that will cause parsing to fail.
    class Base
      def self.method_missing(*)
      end
    end
  end
end
