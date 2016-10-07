source 'https://rubygems.org'

gem 'rake', '>= 10.4.2', require: false
gem 'activerecord', '>= 4.2.5', require: false

group :development do
  gem 'mg', require: false
  gem 'bump'
  platforms :mri, :mingw do
    gem 'yard', require: false
  end
end

group :development, :test do
  gem 'rspec', require: false
  gem 'guard-rspec', require: false
  gem 'terminal-notifier-guard', require: false
  gem 'simplecov', require: false
  gem 'rubocop', '~> 0.37.2', require: false unless RUBY_VERSION =~ /^1.8/
  gem 'coveralls'
  gem 'codeclimate-test-reporter'
  gem 'ruby_dep', '1.3.1'

  platforms :mri, :mingw do
    gem 'pry', require: false
    gem 'pry-coolline', require: false
  end
end

group :test do
  gem 'wrong', require: false
  gem 'files', require: false
end
