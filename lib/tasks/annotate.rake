def is_plugin?
  (defined? ANNOTATE_MODELS_PREFS::USE_PLUGIN) && 
      (!ANNOTATE_MODELS_PREFS::USE_PLUGIN.nil?) ? 
      ANNOTATE_MODELS_PREFS::USE_PLUGIN : false
end

desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :environment do
  if is_plugin?
    require File.expand_path(File.dirname(__FILE__) + '/../annotate/annotate_models')
  else
    require 'annotate_models'
  end

  options={}
  options[:position_in_class] = ENV['position_in_class'] || ENV['position']
  options[:position_in_fixture] = ENV['position_in_fixture'] || ENV['position']  
  options[:include_version] = ENV['include_version']
  AnnotateModels.do_annotations(options)
end

desc "Remove schema information from model and fixture files"
task :remove_annotation => :environment do
  if is_plugin?
    require File.expand_path(File.dirname(__FILE__) + '/../annotate/annotate_models')
  else
    require 'annotate_models'
  end
  AnnotateModels.remove_annotations
end