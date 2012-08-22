$:.unshift(File.dirname(__FILE__))
require 'annotate/version'

module Annotate
  def self.load_tasks
    if File.exists?('Rakefile')
      require 'rake'
      load 'Rakefile'

      Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
      return true
    else
      return false
    end
  end
end
