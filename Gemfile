source 'https://rubygems.org'

ruby '>= 2.2.0'

gem 'activerecord', '>= 4.2.5', require: false
gem 'rake', require: false

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

  gem 'rubocop', '~> 0.46.0', require: false unless RUBY_VERSION =~ /^1.8/
  gem 'simplecov', require: false
  gem 'terminal-notifier-guard', require: false

  gem 'codeclimate-test-reporter'
  gem 'coveralls'

  gem 'overcommit'
  gem 'ruby_dep', '1.3.1'

  platforms :mri, :mingw do
    gem 'pry', require: false
    gem 'pry-coolline', require: false
  end
end

group :test do
  gem 'files', require: false
  gem 'wrong', require: false
end
