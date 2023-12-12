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
  ENV['position'] = options[:position] = Annotate::Helpers.fallback(ENV.fetch('position', nil), 'before')
  options[:additional_file_patterns] = ENV['additional_file_patterns'] ? ENV['additional_file_patterns'].split(',') : []
  options[:position_in_class] = Annotate::Helpers.fallback(ENV.fetch('position_in_class', nil), ENV.fetch('position', nil))
  options[:position_in_fixture] = Annotate::Helpers.fallback(ENV.fetch('position_in_fixture', nil), ENV.fetch('position', nil))
  options[:position_in_factory] = Annotate::Helpers.fallback(ENV.fetch('position_in_factory', nil), ENV.fetch('position', nil))
  options[:position_in_test] = Annotate::Helpers.fallback(ENV.fetch('position_in_test', nil), ENV.fetch('position', nil))
  options[:position_in_serializer] = Annotate::Helpers.fallback(ENV.fetch('position_in_serializer', nil), ENV.fetch('position', nil))
  options[:show_check_constraints] = Annotate::Helpers.true?(ENV.fetch('show_check_constraints', nil))
  options[:show_foreign_keys] = Annotate::Helpers.true?(ENV.fetch('show_foreign_keys', nil))
  options[:show_complete_foreign_keys] = Annotate::Helpers.true?(ENV.fetch('show_complete_foreign_keys', nil))
  options[:show_indexes] = Annotate::Helpers.true?(ENV.fetch('show_indexes', nil))
  options[:simple_indexes] = Annotate::Helpers.true?(ENV.fetch('simple_indexes', nil))
  options[:model_dir] = ENV['model_dir'] ? ENV['model_dir'].split(',') : ['app/models']
  options[:root_dir] = ENV.fetch('root_dir', nil)
  options[:include_version] = Annotate::Helpers.true?(ENV.fetch('include_version', nil))
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:exclude_tests] = Annotate::Helpers.true?(ENV.fetch('exclude_tests', nil))
  options[:exclude_factories] = Annotate::Helpers.true?(ENV.fetch('exclude_factories', nil))
  options[:exclude_fixtures] = Annotate::Helpers.true?(ENV.fetch('exclude_fixtures', nil))
  options[:exclude_serializers] = Annotate::Helpers.true?(ENV.fetch('exclude_serializers', nil))
  options[:exclude_scaffolds] = Annotate::Helpers.true?(ENV.fetch('exclude_scaffolds', nil))
  options[:exclude_controllers] = Annotate::Helpers.true?(ENV.fetch('exclude_controllers', 'true'))
  options[:exclude_helpers] = Annotate::Helpers.true?(ENV.fetch('exclude_helpers', 'true'))
  options[:exclude_sti_subclasses] = Annotate::Helpers.true?(ENV.fetch('exclude_sti_subclasses', nil))
  options[:ignore_model_sub_dir] = Annotate::Helpers.true?(ENV.fetch('ignore_model_sub_dir', nil))
  options[:format_bare] = Annotate::Helpers.true?(ENV.fetch('format_bare', nil))
  options[:format_rdoc] = Annotate::Helpers.true?(ENV.fetch('format_rdoc', nil))
  options[:format_yard] = Annotate::Helpers.true?(ENV.fetch('format_yard', nil))
  options[:format_markdown] = Annotate::Helpers.true?(ENV.fetch('format_markdown', nil))
  options[:sort] = Annotate::Helpers.true?(ENV.fetch('sort', nil))
  options[:force] = Annotate::Helpers.true?(ENV.fetch('force', nil))
  options[:frozen] = Annotate::Helpers.true?(ENV.fetch('frozen', nil))
  options[:classified_sort] = Annotate::Helpers.true?(ENV.fetch('classified_sort', nil))
  options[:trace] = Annotate::Helpers.true?(ENV.fetch('trace', nil))
  options[:wrapper_open] = Annotate::Helpers.fallback(ENV.fetch('wrapper_open', nil), ENV.fetch('wrapper', nil))
  options[:wrapper_close] = Annotate::Helpers.fallback(ENV.fetch('wrapper_close', nil), ENV.fetch('wrapper', nil))
  options[:ignore_columns] = ENV.fetch('ignore_columns', nil)
  options[:ignore_routes] = ENV.fetch('ignore_routes', nil)
  options[:hide_limit_column_types] = Annotate::Helpers.fallback(ENV.fetch('hide_limit_column_types', nil), '')
  options[:hide_default_column_types] = Annotate::Helpers.fallback(ENV.fetch('hide_default_column_types', nil), '')
  options[:with_comment] = Annotate::Helpers.true?(ENV.fetch('with_comment', nil))
  options[:with_comment_column] = Annotate::Helpers.true?(ENV.fetch('with_comment_column', nil))
  options[:ignore_unknown_models] = Annotate::Helpers.true?(ENV.fetch('ignore_unknown_models', 'false'))

  AnnotateModels.do_annotations(options)
end

desc 'Remove schema information from model and fixture files'
task remove_annotation: :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options = {is_rake: true}
  options[:model_dir] = ENV.fetch('model_dir', nil)
  options[:root_dir] = ENV.fetch('root_dir', nil)
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:trace] = Annotate::Helpers.true?(ENV.fetch('trace', nil))
  AnnotateModels.remove_annotations(options)
end
