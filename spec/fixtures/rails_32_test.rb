TestApp::Application.configure do
  config.action_dispatch.show_exceptions = false
  config.active_record.mass_assignment_sanitizer = :strict
  config.active_support.deprecation = :stderr
  config.cache_classes = true
  config.consider_all_requests_local = true
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"
  config.whiny_nils = true
end
