# load 'deploy'
# load 'config/deploy'
# require 'capistrano/sidekiq'
# require 'bundler/capistrano'
# require 'rvm/capistrano'
# require 'capistrano/ext/multistage'



# Load DSL and Setup Up Stages
require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/rvm'
require 'capistrano/bundler'
require 'capistrano/rails/migrations'
# require 'capistrano/sidekiq' # Команды выполняются в sysctl на сервере, конфиг у админа
require 'capistrano3/unicorn'
require 'whenever/capistrano'
require 'rollbar/capistrano3'

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#

# require 'capistrano/rbenv'
# require 'capistrano/chruby'
# require 'capistrano/bundler'



# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
