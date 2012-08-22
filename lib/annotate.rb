$:.unshift(File.dirname(__FILE__))
require 'annotate/version'

module Annotate
  def self.loaded_tasks=(val); @loaded_tasks = val; end
  def self.loaded_tasks; return @loaded_tasks; end

  def self.load_tasks
    if File.exists?('Rakefile')
      return if(self.loaded_tasks)
      self.loaded_tasks = true

      require 'rake'
      load './Rakefile'

      Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
      return true
    else
      return false
    end
  end
end
