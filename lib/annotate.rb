unless defined?(Annotate)
  $:.unshift(File.dirname(__FILE__))

  module Annotate
    VERSION = '2.0.1'
  end

  begin
   load 'Rakefile' 
   Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
  rescue LoadError => e
    nil
  end
end