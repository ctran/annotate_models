desc "Prepends the route map to the top of routes.rb"
task :annotate_routes do
  require 'annotate/annotate_routes'
  AnnotateRoutes.do_annotate
end
