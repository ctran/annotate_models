desc "Adds the route map to routes.rb"
task :annotate_routes => :environment do
  annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))
  require "#{annotate_lib}/annotate/annotate_routes"

  options={}
  ENV['position'] = options[:position] = Annotate.fallback(ENV['position'], 'before')
  options[:position_in_routes] = Annotate.fallback(ENV['position_in_routes'], ENV['position'])
  options[:ignore_routes] = Annotate.fallback(ENV['ignore_routes'],  nil)
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:wrapper_open] = Annotate.fallback(ENV['wrapper_open'], ENV['wrapper'])
  options[:wrapper_close] = Annotate.fallback(ENV['wrapper_close'], ENV['wrapper'])
  AnnotateRoutes.do_annotations(options)
end

desc "Removes the route map from routes.rb"
task :remove_routes => :environment do
  annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))
  require "#{annotate_lib}/annotate/annotate_routes"

  options={}
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  AnnotateRoutes.remove_annotations(options)
end
