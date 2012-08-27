TestApp::Application.configure do
  config.action_dispatch.best_standards_support = :builtin
  config.active_record.auto_explain_threshold_in_seconds = 0.5
  config.active_record.mass_assignment_sanitizer = :strict
  config.active_support.deprecation = :log
  config.assets.compress = false
  config.assets.debug = true
  config.cache_classes = false
  config.consider_all_requests_local = true
  config.whiny_nils = true
end
