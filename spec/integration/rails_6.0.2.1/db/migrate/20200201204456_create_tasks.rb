class CreateTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :tasks do |t|
      t.string :content
      t.integer :count, default: 0
      t.boolean :status, default: false

      t.timestamps
    end
  end
end
