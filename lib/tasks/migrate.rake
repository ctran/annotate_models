# These tasks are added to the project if you install annotate as a Rails plugin.
# (They are not used to build annotate itself.)

# Append annotations to Rake tasks for ActiveRecord, so annotate automatically gets
# run after doing db:migrate.

namespace :db do
  [:migrate, :rollback].each do |cmd|
    task cmd do
      Rake::Task['set_annotation_options'].invoke
      Annotate::Migration.update_annotations
    end

    namespace cmd do
      [:change, :up, :down, :reset, :redo].each do |t|
        task t do
          Rake::Task['set_annotation_options'].invoke
          Annotate::Migration.update_annotations
        end
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
        if Rake::Task.task_defined?("annotate_models")
          Rake::Task["annotate_models"].invoke
        elsif Rake::Task.task_defined?("app:annotate_models")
          Rake::Task["app:annotate_models"].invoke
        else
          raise "Don't know how to build task 'annotate_models'"
        end
      end
    end
  end
end
