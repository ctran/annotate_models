# secret_token.rb
TestApp::Application.config.secret_token = '4768b21141022d583b141fde0db7e0b31759321b7fce459963914fdd82db248ea0318d9568030dcde70d404d4e86003ce5f51a7a83c8130842e5a97062b68c3c'

# session_store.rb
TestApp::Application.config.session_store :cookie_store, key: '_session'

# wrap_parameters.rb
ActiveSupport.on_load(:active_record) { self.include_root_in_json = false }
