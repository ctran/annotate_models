# These tasks are added to the project if you install annotate as a Rails plugin.
# (They are not used to build annotate itself.)

# Append annotations to Rake tasks for ActiveRecord, so annotate automatically gets
# run after doing db:migrate.

%w(db:migrate db:migrate:up db:migrate:down db:migrate:reset db:migrate:redo db:rollback).each do |task|
  Rake::Task[task].enhance do
    Rake::Task[Rake.application.top_level_tasks.last].enhance do
      Rake::Task['set_annotation_options'].invoke
      Annotate::Migration.update_annotations
    end
  end
end

module Annotate
  class Migration
    @@working = false

    def self.update_annotations
      unless @@working || Annotate.skip_on_migration?
        @@working = true

        self.update_models if Annotate.include_models?
        self.update_routes if Annotate.include_routes?
      end
    end

    def self.update_models
      if Rake::Task.task_defined?("annotate_models")
        Rake::Task["annotate_models"].invoke
      elsif Rake::Task.task_defined?("app:annotate_models")
        Rake::Task["app:annotate_models"].invoke
      end
    end

    def self.update_routes
      if Rake::Task.task_defined?("annotate_routes")
        Rake::Task["annotate_routes"].invoke
      end
    end
  end
end
