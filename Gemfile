source 'https://rubygems.org'

gem 'rake', '>= 0.8.7', :require => false
gem 'activerecord', '>= 2.3.0', :require => false

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

  platforms :mri do
    gem 'pry', :require => false
    gem 'pry-coolline', :require => false
  end
end

group :test do
  gem 'wrong', '>=0.6.2', :require => false
  gem 'files', '>=0.2.1', :require => false
end
