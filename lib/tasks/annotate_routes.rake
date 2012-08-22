desc "Adds the route map to routes.rb"
task :annotate_routes => :environment do
  annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))
  require "#{annotate_lib}/annotate/annotate_routes"

  options={}
  options[:position_in_routes] = ENV['position_in_routes'] || ENV['position'] || 'after'
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  AnnotateRoutes.do_annotate(options)
end

desc "Removes the route map from routes.rb"
task :remove_routes => :environment do
  annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))
  require "#{annotate_lib}/annotate/annotate_routes"

  options={}
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  AnnotateRoutes.remove_annotations(options)
end
