LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"
LANGUAGE="en_US.UTF-8"

source 'https://rubygems.org'
ruby '2.3.0'

# Rails
gem 'rails', '4.2.5'
gem 'rails-api', '0.4.0'
gem "sinatra", require: false # for sidekiq

# Server
gem 'unicorn', '~> 4.9.0'
gem 'request_store_rails'
gem 'rack-utf8_sanitizer', '~> 1.2.3'

# Database
gem 'pg', '~> 0.18.1'
gem 'redis-objects'
gem 'redis-namespace'
gem 'postgres-copy'
gem 'connection_pool'

# Workers
gem 'sidekiq'
gem 'sidekiq-limit_fetch'
gem 'sidekiq-failures'
gem "bunny", ">= 2.6.1"

# Services
gem 'rollbar'
gem 'newrelic_rpm'
gem 'newrelic_moped'
gem 'god'
gem 'webpush'
gem 'slack-notifier'
gem 'grocer' # webpush safari

# Tools
gem 'foreman', '~> 0.63.0'
gem 'subcontractor', '~> 0.8.0' # ?
gem 'httparty'
gem 'net-sftp'
gem 'figaro'
gem 'addressable', '~> 2.3', '>= 2.3.8'
gem 'open_uri_redirections'
gem 'liquid'

# Crontab
gem 'whenever', '~> 0.9.2', require: false

# Mailing
gem 'dkim', '~> 1.0.0' # Ставит цифровые подписи
gem 'bounce_email', '~> 0.2.6', require: false # Определяет тип баунса
gem 'slim-rails'

# Upload files
gem 'paperclip'#, '~> 4.3.7'

# Internal
gem 'brb', '~> 0.3.1'
gem "rees46_ml", path: "vendor/gems/rees46_ml"
gem "size_tables", path: "vendor/gems/size_tables"

group :development do
  gem 'stackprof'
  gem 'dotenv-rails', '~> 0.8.0' # ?
  gem 'letter_opener', '~> 1.2.0'
  gem 'capistrano'
  gem 'capistrano-rvm'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-sidekiq'
  gem 'capistrano3-unicorn'
  gem 'jazz_hands', github: 'nixme/jazz_hands', branch: 'bring-your-own-debugger'
end

# Rspec
group :development, :test do
  gem 'pry'
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
  gem 'rspec-sidekiq'
end

