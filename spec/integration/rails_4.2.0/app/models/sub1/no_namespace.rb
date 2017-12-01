class NoNamespace < ActiveRecord::Base
  enum foo: [:bar, :baz]
end
