annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))

unless ENV['is_cli']
  task :set_annotation_options
  task annotate_routes: :set_annotation_options
end

desc "Adds the route map to routes.rb"
task :annotate_routes => :environment do
  require "#{annotate_lib}/annotate/annotate_routes"

  options={}
  ENV['position'] = options[:position] = Annotate::Helpers.fallback(ENV.fetch('position', nil), 'before')
  options[:position_in_routes] = Annotate::Helpers.fallback(ENV.fetch('position_in_routes', nil), ENV.fetch('position', nil))
  options[:ignore_routes] = Annotate::Helpers.fallback(ENV.fetch('ignore_routes', nil),  nil)
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:frozen] = Annotate::Helpers.true?(ENV.fetch('frozen', nil))
  options[:wrapper_open] = Annotate::Helpers.fallback(ENV.fetch('wrapper_open', nil), ENV.fetch('wrapper', nil))
  options[:wrapper_close] = Annotate::Helpers.fallback(ENV.fetch('wrapper_close', nil), ENV.fetch('wrapper', nil))
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
