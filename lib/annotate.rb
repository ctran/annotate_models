$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

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
      load 'Rakefile'
      Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
      return true
    else
      return false
    end
  end
end
