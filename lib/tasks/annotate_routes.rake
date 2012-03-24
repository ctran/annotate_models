desc "Prepends the route map to the top of routes.rb"
task :annotate_routes => :environment do
  annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))
  require "#{annotate_lib}/annotate/annotate_routes"
  AnnotateRoutes.do_annotate
end
