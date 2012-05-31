# monkey patches

module ::ActiveRecord
  class Base
    def self.method_missing(name, *args)
      # ignore this, so unknown/unloaded macros won't cause parsing to fail
    end
  end
end