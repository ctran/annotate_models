class AddEnumTypeFieldToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :type_field, :integer, default: 0
  end
end
