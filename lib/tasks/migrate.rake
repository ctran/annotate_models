# These tasks are added to the project if you install annotate as a Rails plugin.
# (They are not used to build annotate itself.)

# Append annotations to Rake tasks for ActiveRecord, so annotate automatically gets
# run after doing db:migrate.

namespace :db do
  task :migrate do
    Rake::Task['set_annotation_options'].invoke
    Annotate::Migration.update_annotations
  end

  namespace :migrate do
    [:change, :up, :down, :reset, :redo].each do |t|
      task t do
        Rake::Task['set_annotation_options'].invoke
        Annotate::Migration.update_annotations
      end
    end
  end
end

module Annotate
  class Migration
    @@working = false

    def self.update_annotations
      unless @@working || Annotate.skip_on_migration?
        @@working = true
        Rake::Task['annotate_models'].invoke
      end
    end
  end
end
