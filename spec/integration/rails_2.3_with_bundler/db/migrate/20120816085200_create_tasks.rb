class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string :content

      t.timestamps
    end
  end

  def self.down
    drop_table :tasks
  end
end
