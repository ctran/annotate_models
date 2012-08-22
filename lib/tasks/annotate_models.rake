annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))

if(!ENV['is_cli'])
  task :set_annotation_options
  task :annotate_models => :set_annotation_options
end

desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options={ :is_rake => true }
  ENV['position'] = options[:position] = Annotate.fallback(ENV['position'], 'before')
  options[:position_in_class] = Annotate.fallback(ENV['position_in_class'], ENV['position'])
  options[:position_in_fixture] = Annotate.fallback(ENV['position_in_fixture'], ENV['position'])
  options[:position_in_factory] = Annotate.fallback(ENV['position_in_factory'], ENV['position'])
  options[:position_in_test] = Annotate.fallback(ENV['position_in_test'], ENV['position'])
  options[:show_indexes] = Annotate.true?(ENV['show_indexes'])
  options[:simple_indexes] = Annotate.true?(ENV['simple_indexes'])
  options[:model_dir] = ENV['model_dir']
  options[:include_version] = Annotate.true?(ENV['include_version'])
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:exclude_tests] = Annotate.true?(ENV['exclude_tests'])
  options[:exclude_factories] = Annotate.true?(ENV['exclude_factories'])
  options[:exclude_fixtures] = Annotate.true?(ENV['exclude_fixtures'])
  options[:ignore_model_sub_dir] = Annotate.true?(ENV['ignore_model_sub_dir'])
  options[:format_bare] = Annotate.true?(ENV['format_bare'])
  options[:format_rdoc] = Annotate.true?(ENV['format_rdoc'])
  options[:format_markdown] = Annotate.true?(ENV['format_markdown'])
  options[:sort] = Annotate.true?(ENV['sort'])
  options[:force] = Annotate.true?(ENV['force'])
  options[:trace] = Annotate.true?(ENV['trace'])
  AnnotateModels.do_annotations(options)
end

desc "Remove schema information from model and fixture files"
task :remove_annotation => :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options={ :is_rake => true }
  options[:model_dir] = ENV['model_dir']
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:trace] = Annotate.true?(ENV['trace'])
  AnnotateModels.remove_annotations(options)
end
