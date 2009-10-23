desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :environment do
  require 'annotate/annotate_models'
  options={}
  options[:position_in_class] = ENV['position_in_class'] || ENV['position'] || :before
  options[:position_in_fixture] = ENV['position_in_fixture'] || ENV['position']  || :before
  options[:show_indexes] = ENV['show_indexes']
  options[:simple_indexes] = ENV['simple_indexes']
  options[:model_dir] = ENV['model_dir']
  options[:include_version] = ENV['include_version']
  options[:require] = ENV['require'] ? ENV['require'].split(',') : []
  AnnotateModels.do_annotations(options)
end

desc "Remove schema information from model and fixture files"
task :remove_annotation => :environment do
  require 'annotate/annotate_models'
  options={}
  options[:model_dir] = ENV['model_dir']
  AnnotateModels.remove_annotations(options)
end
