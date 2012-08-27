# new_rails_defaults.rb
if defined?(ActiveRecord)
  ActiveRecord::Base.include_root_in_json = true
  ActiveRecord::Base.store_full_sti_class = true
end
ActionController::Routing.generate_best_match = false
ActiveSupport.use_standard_json_time_format = true
ActiveSupport.escape_html_entities_in_json = false

# session_store.rb
ActionController::Base.session = {
  :key         => '_session',
  :secret      => 'a61ce930be7219beee70d3e3411e0794d90ab22d12e87a1f7f50c98ad7b08771ed92e72e1a7299c8ec4795d45d566a39e0a0a1f7e7095e2eeb31320a0c5d7ee5'
}

# cookie_verification_secret.rb
ActionController::Base.cookie_verifier_secret = '1b2363a161fbf01041bd9d0b0d9a332e5c7445503c9e89585c8a248698d28054e3918fa77a0206e662629ee9a00d2831949e74801f27ee85ba2116b62b675935';

# Hacks for Ruby 1.9.3...
MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]
