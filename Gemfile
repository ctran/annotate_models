source 'https://rubygems.org'

ruby '>= 3.3.0'

gem 'activerecord', '>= 7.1', require: false
gem 'rake', require: false
gem 'activerecord-multi-tenant', git: 'https://github.com/citusdata/activerecord-multi-tenant.git', require: false

group :development do
  gem 'bump'
  gem 'mg', require: false
  platforms :mri, :mingw do
    gem 'yard', require: false
  end
end

group :development, :test do
  gem 'byebug'
  gem 'guard-rspec', require: false
  gem 'rspec', require: false

  gem 'rubocop', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'terminal-notifier-guard', require: false

  gem 'codeclimate-test-reporter'
  gem 'coveralls'

  gem 'overcommit'

  platforms :mri, :mingw do
    gem 'pry', require: false
    gem 'pry-byebug', require: false
  end
end

group :test do
  gem 'files', require: false
  gem 'git', require: false
end
