class CreateTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :tasks do |t|
      t.boolean :completed, null: false
      t.string :description

      t.timestamps
    end
  end
end
