annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))

if(!ENV['is_cli'])
  task :set_annotation_options
  task :annotate_models => :set_annotation_options
end

desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  true_re = /(true|t|yes|y|1)$/i

  options={ :is_rake => true }
  options[:position_in_class] = ENV['position_in_class'] || ENV['position'] || 'before'
  options[:position_in_fixture] = ENV['position_in_fixture'] || ENV['position']  || 'before'
  options[:position_in_factory] = ENV['position_in_factory'] || ENV['position'] || 'before'
  options[:show_indexes] = ENV['show_indexes'] =~ true_re
  options[:simple_indexes] = ENV['simple_indexes'] =~ true_re
  options[:model_dir] = ENV['model_dir']
  options[:include_version] = ENV['include_version'] =~ true_re
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  options[:exclude_tests] = ENV['exclude_tests'] =~ true_re
  options[:exclude_fixtures] = ENV['exclude_fixtures'] =~ true_re
  options[:ignore_model_sub_dir] = ENV['ignore_model_sub_dir'] =~ true_re
  options[:format_rdoc] = ENV['format_rdoc'] =~ true_re
  options[:format_markdown] = ENV['format_markdown'] =~ true_re
  options[:sort] = ENV['sort'] =~ true_re
  options[:force] = ENV['force'] =~ true_re
  options[:trace] = ENV['trace'] =~ true_re
  AnnotateModels.do_annotations(options)
end

desc "Remove schema information from model and fixture files"
task :remove_annotation => :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"
  options={ :is_rake => true }
  options[:model_dir] = ENV['model_dir']
  AnnotateModels.remove_annotations(options)
end
