desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :environment do
  require 'annotate_models'
  options={}
  options[:position_in_class] = ENV['position_in_class'] || ENV['position']
  options[:position_in_fixture] = ENV['position_in_fixture'] || ENV['position']  
  AnnotateModels.do_annotations(options)
end

desc "Remove schema information from model and fixture files"
task :remove_annotation => :environment do
  require 'annotate_models'
  AnnotateModels.remove_annotations
end