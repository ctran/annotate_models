annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))

unless ENV['is_cli']
  task :set_annotation_options
  task annotate_models: :set_annotation_options
end

desc 'Add schema information (as comments) to model and fixture files'
task annotate_models: :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options = {is_rake: true}
  ENV['position'] = options[:position] = Annotate::Helpers.fallback(ENV['position'], 'before')
  options[:additional_file_patterns] = ENV['additional_file_patterns'] ? ENV['additional_file_patterns'].split(',') : []
  options[:position_in_class] = Annotate::Helpers.fallback(ENV['position_in_class'], ENV['position'])
  options[:position_in_fixture] = Annotate::Helpers.fallback(ENV['position_in_fixture'], ENV['position'])
  options[:position_in_factory] = Annotate::Helpers.fallback(ENV['position_in_factory'], ENV['position'])
  options[:position_in_test] = Annotate::Helpers.fallback(ENV['position_in_test'], ENV['position'])
  options[:position_in_serializer] = Annotate::Helpers.fallback(ENV['position_in_serializer'], ENV['position'])
  options[:show_foreign_keys] = Annotate::Helpers.true?(ENV['show_foreign_keys'])
  options[:show_complete_foreign_keys] = Annotate::Helpers.true?(ENV['show_complete_foreign_keys'])
  options[:show_indexes] = Annotate::Helpers.true?(ENV['show_indexes'])
  options[:simple_indexes] = Annotate::Helpers.true?(ENV['simple_indexes'])
  options[:model_dir] = ENV['model_dir'] ? ENV['model_dir'].split(',') : ['app/models']
  options[:root_dir] = ENV['root_dir']
  options[:include_version] = Annotate::Helpers.true?(ENV['include_version'])
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:exclude_tests] = Annotate::Helpers.true?(ENV['exclude_tests'])
  options[:exclude_factories] = Annotate::Helpers.true?(ENV['exclude_factories'])
  options[:exclude_fixtures] = Annotate::Helpers.true?(ENV['exclude_fixtures'])
  options[:exclude_serializers] = Annotate::Helpers.true?(ENV['exclude_serializers'])
  options[:exclude_scaffolds] = Annotate::Helpers.true?(ENV['exclude_scaffolds'])
  options[:exclude_controllers] = Annotate::Helpers.true?(ENV.fetch('exclude_controllers', 'true'))
  options[:exclude_helpers] = Annotate::Helpers.true?(ENV.fetch('exclude_helpers', 'true'))
  options[:exclude_sti_subclasses] = Annotate::Helpers.true?(ENV['exclude_sti_subclasses'])
  options[:ignore_model_sub_dir] = Annotate::Helpers.true?(ENV['ignore_model_sub_dir'])
  options[:format_bare] = Annotate::Helpers.true?(ENV['format_bare'])
  options[:format_rdoc] = Annotate::Helpers.true?(ENV['format_rdoc'])
  options[:format_yard] = Annotate::Helpers.true?(ENV['format_yard'])
  options[:format_markdown] = Annotate::Helpers.true?(ENV['format_markdown'])
  options[:sort] = Annotate::Helpers.true?(ENV['sort'])
  options[:force] = Annotate::Helpers.true?(ENV['force'])
  options[:frozen] = Annotate::Helpers.true?(ENV['frozen'])
  options[:classified_sort] = Annotate::Helpers.true?(ENV['classified_sort'])
  options[:trace] = Annotate::Helpers.true?(ENV['trace'])
  options[:wrapper_open] = Annotate::Helpers.fallback(ENV['wrapper_open'], ENV['wrapper'])
  options[:wrapper_close] = Annotate::Helpers.fallback(ENV['wrapper_close'], ENV['wrapper'])
  options[:ignore_columns] = ENV.fetch('ignore_columns', nil)
  options[:ignore_routes] = ENV.fetch('ignore_routes', nil)
  options[:hide_limit_column_types] = Annotate::Helpers.fallback(ENV['hide_limit_column_types'], '')
  options[:hide_default_column_types] = Annotate::Helpers.fallback(ENV['hide_default_column_types'], '')
  options[:with_comment] = Annotate::Helpers.true?(ENV['with_comment'])
  options[:ignore_unknown_models] = Annotate::Helpers.true?(ENV.fetch('ignore_unknown_models', 'false'))

  AnnotateModels.do_annotations(options)
end

desc 'Remove schema information from model and fixture files'
task remove_annotation: :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options = {is_rake: true}
  options[:model_dir] = ENV['model_dir']
  options[:root_dir] = ENV['root_dir']
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:trace] = Annotate::Helpers.true?(ENV['trace'])
  AnnotateModels.remove_annotations(options)
end
