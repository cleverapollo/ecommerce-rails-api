LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

source 'https://rubygems.org'
ruby '2.2.3'

# Rails
gem 'rails', '4.2.4'
gem 'rails-api', '0.4.0'
gem "sinatra", require: false # for sidekiq

# Server
gem 'unicorn', '~> 4.9.0'
gem 'request_store_rails'
gem 'rack-utf8_sanitizer', '~> 1.2.3'

# Database
gem 'pg', '~> 0.18.1'
gem 'redis-objects'
gem 'mongoid', '~> 5.0.0'
gem 'connection_pool'

# Workers
gem 'sidekiq', '~> 3.3.3'
gem 'sidekiq-limit_fetch', '~> 2.4.1'

# Services
gem 'rollbar', '~> 2.4.0'
gem 'newrelic_rpm', '~> 3.12.0'

# Tools
gem 'foreman', '~> 0.63.0'
gem 'subcontractor', '~> 0.8.0' # ?
gem 'httparty', '~> 0.12.0'
gem 'figaro'
gem 'addressable', '~> 2.3', '>= 2.3.8'

# Crontab
gem 'whenever', '~> 0.9.2', require: false

# Mailing
gem 'dkim', '~> 1.0.0' # Ставит цифровые подписи
gem 'gmail', github: 'gmailgem/gmail', require: false # Вытаскивает боунсы писем из bounced@rees46.com
gem 'bounce_email', '~> 0.2.6', require: false # Определяет тип баунса

# Upload files
gem 'paperclip', '~> 4.2.1'

# Internal
gem 'brb', '~> 0.3.1'
gem "rees46_ml", path: "vendor/gems/rees46_ml"
gem "size_tables", path: "vendor/gems/size_tables"

group :development do
  gem 'pry'
  gem 'dotenv-rails', '~> 0.8.0' # ?
  gem 'letter_opener', '~> 1.2.0'
  gem 'capistrano'
  gem 'capistrano-rvm'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-sidekiq'
  gem 'capistrano3-unicorn'
end

# Rspec
group :development, :test do
  gem 'timecop', '~> 0.7.1' # Изменяет в тестах текущее время
  gem 'rspec-rails', '~> 3.1.0'
  gem 'thin'
end

# Test tools
group :test do
  gem 'simplecov', '~> 0.7.1', require: false # Статистика покрытия
  gem 'factory_girl_rails', '~> 4.5.0' # Объекты для тестов
  gem 'database_cleaner', '~> 1.3.0'
  gem 'ffaker', '~> 1.25.0' # Генерирует данные (имя, e-mail) для тестов
end

