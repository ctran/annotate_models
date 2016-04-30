annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))

unless ENV['is_cli']
  task :set_annotation_options
  task annotate_models: :set_annotation_options
end

desc 'Add schema information (as comments) to model and fixture files'
task annotate_models: :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options={is_rake: true}
  ENV['position'] = options[:position] = Annotate.fallback(ENV['position'], 'before')
  options[:position_in_class] = Annotate.fallback(ENV['position_in_class'], ENV['position'])
  options[:position_in_fixture] = Annotate.fallback(ENV['position_in_fixture'], ENV['position'])
  options[:position_in_factory] = Annotate.fallback(ENV['position_in_factory'], ENV['position'])
  options[:position_in_test] = Annotate.fallback(ENV['position_in_test'], ENV['position'])
  options[:position_in_serializer] = Annotate.fallback(ENV['position_in_serializer'], ENV['position'])
  options[:include_model] = Annotate.true?(ENV['include_model'])
  options[:include_test] = Annotate.true?(ENV['include_test'])
  options[:include_fixture] = Annotate.true?(ENV['include_fixture'])
  options[:include_factory] = Annotate.true?(ENV['include_factory'])
  options[:include_serializer] = Annotate.true?(ENV['include_serializer'])
  options[:include_scaffold] = Annotate.true?(ENV['include_scaffold'])
  options[:include_controller] = Annotate.true?(ENV['include_controller'])
  options[:include_helper] = Annotate.true?(ENV['include_helper'])
  options[:include_route] = Annotate.true?(ENV['include_route'])
  options[:include_admin] = Annotate.true?(ENV['include_admin'])
  options[:show_foreign_keys] = Annotate.true?(ENV['show_foreign_keys'])
  options[:show_indexes] = Annotate.true?(ENV['show_indexes'])
  options[:simple_indexes] = Annotate.true?(ENV['simple_indexes'])
  options[:model_dir] = ENV['model_dir'] ? ENV['model_dir'].split(',') : ['app/models']
  options[:root_dir] = ENV['root_dir'] ? ENV['root_dir'].split(',') : ['']
  options[:include_version] = Annotate.true?(ENV['include_version'])
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:exclude_tests] = Annotate.true?(ENV['exclude_tests'])
  options[:exclude_factories] = Annotate.true?(ENV['exclude_factories'])
  options[:exclude_fixtures] = Annotate.true?(ENV['exclude_fixtures'])
  options[:exclude_serializers] = Annotate.true?(ENV['exclude_serializers'])
  options[:exclude_scaffolds] = Annotate.true?(ENV['exclude_scaffolds'])
  options[:exclude_controllers] = Annotate.true?(ENV.fetch('exclude_controllers', 'true'))
  options[:exclude_helpers] = Annotate.true?(ENV.fetch('exclude_helpers', 'true'))
  options[:ignore_model_sub_dir] = Annotate.true?(ENV['ignore_model_sub_dir'])
  options[:format_bare] = Annotate.true?(ENV['format_bare'])
  options[:format_rdoc] = Annotate.true?(ENV['format_rdoc'])
  options[:format_markdown] = Annotate.true?(ENV['format_markdown'])
  options[:sort] = Annotate.true?(ENV['sort'])
  options[:force] = Annotate.true?(ENV['force'])
  options[:classified_sort] = Annotate.true?(ENV['classified_sort'])
  options[:trace] = Annotate.true?(ENV['trace'])
  options[:wrapper_open] = Annotate.fallback(ENV['wrapper_open'], ENV['wrapper'])
  options[:wrapper_close] = Annotate.fallback(ENV['wrapper_close'], ENV['wrapper'])
  options[:ignore_columns] = ENV.fetch('ignore_columns', nil)
  options[:ignore_routes] = ENV.fetch('ignore_routes', nil)
  options[:hide_limit_column_types] = Annotate.fallback(ENV['hide_limit_column_types'], '')

  AnnotateModels.do_annotations(options)
end

desc 'Remove schema information from model and fixture files'
task remove_annotation: :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options={is_rake: true}
  options[:model_dir] = ENV['model_dir']
  options[:root_dir] = ENV['root_dir']
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:trace] = Annotate.true?(ENV['trace'])
  AnnotateModels.remove_annotations(options)
end
