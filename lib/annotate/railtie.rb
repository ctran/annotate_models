require 'annotate'
require 'rails'
module Annotate
  class Railtie < Rails::Railtie
    railtie_name :annotate

    rake_tasks do
      load "tasks/annotate_models.rake"
    end
  end
end
