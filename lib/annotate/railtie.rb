require 'annotate'
require 'rails'

module Annotate
  class Railtie < Rails::Railtie
    railtie_name :annotate
    
    rake_tasks do
      load "lib/tasks/annotate_models.rake"
      load "lib/tasks/annotate_old.rake"
    end
  end
end
