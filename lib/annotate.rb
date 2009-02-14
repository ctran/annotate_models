$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Annotate
  VERSION = '2.2.6'
end

begin
 load 'Rakefile' 
 Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
rescue LoadError => e
  nil
end

