source 'https://rubygems.org'
ruby '2.1.1'

# Rails
gem 'rails', '4.2.0'
gem 'rails-api', '0.4.0'

# Server
gem 'unicorn', '~> 4.8.1'

# Database
gem 'pg', '~> 0.17.1'
gem 'redis-objects', '~> 0.9.0'

# Workers
gem 'sidekiq', '~> 2.17.7'
gem 'sidekiq-limit_fetch', '~> 2.2.5'

# Services
gem 'rollbar', '~> 1.4.4'
gem 'newrelic_rpm', '~> 3.10.0'

# BrB
gem 'brb', '~> 0.3.1'

# Tools
gem 'foreman', '~> 0.63.0'
gem 'subcontractor', '~> 0.8.0'
gem 'httparty', '~> 0.12.0'
gem 'rack-utf8_sanitizer', '~> 1.2.3'

# Crontab
gem 'whenever', '~> 0.9.2', require: false

# Mailing
gem 'dkim', '~> 1.0.0'
gem 'gmail', github: 'gmailgem/gmail', require: false
gem 'bounce_email', '~> 0.2.2', require: false

# Development tools
group :development do
  gem 'dotenv-rails', '~> 0.8.0'
  gem 'better_errors', '~> 1.0.1'
  gem 'binding_of_caller', '~> 0.7.2'
  gem 'letter_opener', '~> 1.2.0'

  # Deploy
  gem 'capistrano', '~> 2.15.5'
  gem 'rvm-capistrano', '~> 1.5.0'
  gem 'capistrano-sidekiq', '~> 0.1.1'

  # Preloader
  gem 'spring', '~> 1.2.0'
  gem 'spring-commands-rspec', '~> 1.0.4'
end

# Rspec
group :development, :test do
  gem 'timecop', '~> 0.7.1'
  gem 'jazz_hands', '~> 0.5.2'
  gem 'rspec-rails', '~> 3.1.0'
  gem 'guard-rspec', '~> 4.5.0', require: false
end

# Test tools
group :test do
  gem 'simplecov', '~> 0.7.1', require: false
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'database_cleaner', '~> 1.3.0'
  gem 'ffaker', '~> 1.25.0'
end

# Documentation
group :doc do
  gem 'yard', '~> 0.8.7.4'
end
