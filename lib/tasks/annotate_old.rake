namespace :db do
  
  desc 'Aliases the old db:annotate task name'
  task :annotate => :environment do
    Rake::Task["annotate_models"].execute
  end
  
  task :migrate do
    Rake::Task["annotate_models"].invoke if Rails.env.development?
  end
  
  # ensures that migrate, reset, redo run annotate.
  
  namespace :migrate do
    [:reset, :redo].each do |t|
      task t do
        Rake::Task["annotate_models"].invoke if Rails.env.development?
      end
    end
  end
end
