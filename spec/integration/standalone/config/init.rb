require 'active_record'

ActiveRecord::Base.establish_connection({
  adapter:  'sqlite3',
  database: 'db/development.sqlite3',
  pool: 1,
  timeout: 5000
})
