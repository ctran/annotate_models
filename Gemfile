source 'https://rubygems.org'

gem 'rake', '>= 10.4.2', :require => false
gem 'activerecord', '>= 4.2.5', :require => false

group :development do
  gem 'mg', :require => false
  gem 'bump'
  platforms :mri do
    gem 'yard', :require => false
  end
end

group :development, :test do
  gem 'rspec', :require => false
  gem 'guard-rspec', :require => false
  gem 'terminal-notifier-guard', :require => false
  gem 'rubocop', :require => false unless RUBY_VERSION =~ /^1.8/

  platforms :mri do
    gem 'pry', :require => false
    gem 'pry-coolline', :require => false
  end
end

group :test do
  gem 'wrong', :require => false
  gem 'files', :require => false
end
