# These tasks are added to the project if you install annotate as a Rails plugin.
# (They are not used to build annotate itself.)

# Append annotations to Rake tasks for ActiveRecord, so annotate automatically gets
# run after doing db:migrate. 
# Unfortunately it relies on ENV for options; it'd be nice to be able to set options
# in a per-project config file so this task can read them.
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
