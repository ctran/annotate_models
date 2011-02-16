require 'annotate'
require 'rails'

module Annotate
  class Railtie < Rails::Railtie
    
    rake_tasks do
      load "tasks/annotate_models.rake"
      load "tasks/annotate_old.rake"
    end
  end
end
