$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Annotate
  VERSION = '2.0.2'
  
  def self.load_tasks
    if File.exists?('Rakefile')
      load 'Rakefile'
      Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
      return true
    else
      return false
    end
  end
end