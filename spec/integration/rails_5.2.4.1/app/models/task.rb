class Task < ApplicationRecord
  enum type_field: { inactive: 0, active: 1, archived: 2 }
end
