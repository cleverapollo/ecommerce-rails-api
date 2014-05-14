source 'https://rubygems.org'
ruby '2.0.0'

# Rails
gem 'rails', '4.0.3'
gem 'rails-api', '0.2.0'

# Server
gem 'unicorn', '4.8.1'

# Database
gem 'pg', '0.17.1'
gem 'squeel', '1.1.1'
gem 'redis-objects', '0.9.0'

# Workers
gem 'sidekiq', '2.17.7'

# Services
gem 'rollbar', '0.12.14'
gem 'newrelic_rpm', '3.7.3.199'

# BrB
gem 'brb', '0.3.1'

# Tools
gem 'foreman', '0.63.0'
gem 'subcontractor', '0.8.0'
gem 'zeus', '0.13.3'
gem 'httparty', '0.12.0'

# Development tools
group :development do
  gem 'jazz_hands', '0.5.2'
  gem 'dotenv-rails', '0.8.0'
  gem 'better_errors', '1.0.1'
  gem 'binding_of_caller', '0.7.2'
  gem 'letter_opener', '1.2.0'

  # Deploy
  gem 'capistrano', '2.15.5'
  gem 'rvm-capistrano', '1.5.0'
  gem 'capistrano-sidekiq', '0.1.1'
end

# Rspec
group :development, :test do
  gem 'rspec-rails', '2.14.1'
  gem 'guard-rspec', '4.2.6', require: false
end

# Test tools
group :test do
  gem 'pry'
  gem 'simplecov', '0.7.1', require: false
  gem 'factory_girl_rails', '4.3.0'
end

# Documentation
group :doc do
  gem 'yard', '0.8.7.4'
end
