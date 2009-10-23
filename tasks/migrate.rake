# append annotations to Rake tasks (for ActiveRecord)
namespace :db do
  task :migrate do
    Annotate::Migration.update_annotations
  end

  namespace :migrate do
    [:up, :down, :reset, :redo].each do |t|
      task t do
        Annotate::Migration.update_annotations
      end
    end
  end
end

module Annotate
  class Migration
    @@working = false

    def self.update_annotations
      unless @@working
        @@working = true
        Rake::Task['annotate_models'].invoke
      end
    end
  end
end
