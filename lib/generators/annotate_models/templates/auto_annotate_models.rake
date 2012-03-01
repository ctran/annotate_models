# NOTE: only doing this in development as some production environments (Heroku)
# NOTE: are sensitive to local FS writes, and besides -- it's just not proper
# NOTE: to have a dev-mode tool do its thing in production.
if(Rails.env.development?)
  task :set_annotation_options do
    ENV['position_in_class']    = "before"
    ENV['position_in_fixture']  = "before"
    ENV['position_in_factory']  = "before"
    ENV['show_indexes']         = "true"
    ENV['include_version']      = "false"
    ENV['exclude_tests']        = "false"
    ENV['exclude_fixtures']     = "false"
    ENV['ignore_model_sub_dir'] = "false"
    ENV['skip_on_db_migrate']   = "false"
    ENV['format_rdoc']          = "false"
    ENV['format_markdown']      = "false"
    ENV['no_sort']              = "false"
    ENV['force']                = "false"
  end
end
