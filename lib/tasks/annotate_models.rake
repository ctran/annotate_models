desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'annotate_models'))
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'active_record_patch'))

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
  options[:format_rdoc] = ENV['format_rdoc'] =~ true_re
  AnnotateModels.do_annotations(options)
end

desc "Remove schema information from model and fixture files"
task :remove_annotation => :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'annotate_models'))
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'active_record_patch'))
  options={ :is_rake => true }
  options[:model_dir] = ENV['model_dir']
  AnnotateModels.remove_annotations(options)
end
