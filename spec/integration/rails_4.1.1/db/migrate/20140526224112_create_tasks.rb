class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :content
      t.column :status, :default => 0
      t.timestamps
    end
  end
end
