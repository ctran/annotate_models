
require 'yaml'

module Annotate
  def self.version
    version_file = File.dirname(__FILE__) + "/../VERSION.yml"
    if File.exist?(version_file)
      config = YAML.load(File.read(version_file))
      version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
    else
      version = "0.0.0"
    end
  end

  def self.load_tasks
    if File.exists?('Rakefile')
      require 'rake'
      load 'Rakefile'
      # Rails 3 wants to load our .rake files for us.
      # TODO: selectively do this require on Rails 2.x?
      #Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
      return true
    else
      return false
    end
  end
end
