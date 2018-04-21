require 'annotate'

module Annotate
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Copy annotate_models rakefiles for automatic annotation'
      source_root File.expand_path('templates', __dir__)

      # copy rake tasks
      def copy_tasks
        template 'auto_annotate_models.rake', 'lib/tasks/auto_annotate_models.rake'
      end
    end
  end
end
