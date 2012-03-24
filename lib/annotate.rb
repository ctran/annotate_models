here = File.dirname __FILE__
require "#{here}/annotate/version"

module Annotate
  def self.load_tasks
    if File.exists?('Rakefile')
      require 'rake'
      load 'Rakefile'
      # Rails 3 wants to load our .rake files for us.
      # TODO: selectively do this require on Rails 2.x?
      Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
      return true
    else
      return false
    end
  end
end
