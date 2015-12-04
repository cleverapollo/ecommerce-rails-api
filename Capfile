# load 'deploy'
# load 'config/deploy'
# require 'capistrano/sidekiq'
# require 'bundler/capistrano'
# require 'rvm/capistrano'
# require 'capistrano/ext/multistage'



# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'
require 'whenever/capistrano'

require 'capistrano/rvm'
require 'capistrano/sidekiq'
require 'capistrano/bundler'
require 'capistrano/rails/migrations'
require 'capistrano3/unicorn'

require 'rollbar/capistrano3'

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
