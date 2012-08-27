require File.expand_path('../boot', __FILE__)

require "active_record/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
end

module TestApp
  class Application < Rails::Application
    config.assets.enabled = true
    config.assets.version = '1.0'
  end
end
