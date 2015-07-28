LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

source 'https://rubygems.org'
ruby '2.2.2'

# Rails
gem 'rails', '4.2.3'
gem 'rails-api', '0.4.0'

# Server
gem 'unicorn', '~> 4.8.1'

# Database
gem 'pg', '~> 0.18.1'
gem 'redis-objects', '~> 0.9.0'

# Workers
gem 'sidekiq', '~> 3.3.3'
gem 'sidekiq-limit_fetch', '~> 2.4.1'

# Services
gem 'rollbar', '~> 1.5.3'
gem 'newrelic_rpm', '~> 3.12.0'

# BrB
gem 'brb', '~> 0.3.1'

# Tools
gem 'foreman', '~> 0.63.0'
gem 'subcontractor', '~> 0.8.0' # ?
gem 'httparty', '~> 0.12.0'
gem 'rack-utf8_sanitizer', '~> 1.2.3'
gem 'figaro'

# Crontab
gem 'whenever', '~> 0.9.2', require: false

# Mailing
gem 'dkim', '~> 1.0.0' # Ставит цифровые подписи
gem 'gmail', github: 'gmailgem/gmail', require: false # Вытаскивает боунсы писем из bounced@rees46.com
gem 'bounce_email', '~> 0.2.2', require: false # Определяет тип баунса

# zip
gem 'libarchive-ruby', '0.0.3'

# Development tools
group :development do
  gem 'dotenv-rails', '~> 0.8.0' # ?
  gem 'better_errors', '~> 1.0.1'
  gem 'binding_of_caller', '~> 0.7.2'
  gem 'letter_opener', '~> 1.2.0'

  # Deploy
  gem 'capistrano', '~> 3.4.0'
  gem 'rvm-capistrano'
  gem 'capistrano-rvm'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-sidekiq'


  # Preloader
  gem 'spring', '~> 1.2.0' # ?
  gem 'spring-commands-rspec', '~> 1.0.4'
end

# Rspec
group :development, :test do
  gem 'timecop', '~> 0.7.1' # Изменяет в тестах текущее время
  gem 'jazz_hands', github: 'nixme/jazz_hands', branch: 'bring-your-own-debugger' # Консоль
  gem 'rspec-rails', '~> 3.1.0'
  gem 'guard-rspec', '~> 4.5.0', require: false # Следит за состояние файлов и запускает тесты при изменении файла
  gem 'thin'
end

# Test tools
group :test do
  gem 'simplecov', '~> 0.7.1', require: false # Статистика покрытия
  gem 'factory_girl_rails', '~> 4.5.0' # Объекты для тестов
  gem 'database_cleaner', '~> 1.3.0'
  gem 'ffaker', '~> 1.25.0' # Генерирует данные (имя, e-mail) для тестов
end

# Documentation
group :doc do
  gem 'yard', '~> 0.8.7.4'
end
