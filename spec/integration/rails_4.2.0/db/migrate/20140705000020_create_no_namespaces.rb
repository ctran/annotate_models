class CreateUsers < ActiveRecord::Migration
  def change
    create_table :no_namespaces do |t|
      t.integer :foo
      t.timestamps
    end
  end
end
