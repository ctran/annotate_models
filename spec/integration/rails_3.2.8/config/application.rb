require File.expand_path('../boot', __FILE__)

require "active_record/railtie"
require "rails/test_unit/railtie"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
end

module TestApp
  class Application < Rails::Application
    config.active_record.whitelist_attributes = true
    config.active_support.escape_html_entities_in_json = true
    config.assets.enabled = false
  end
end
