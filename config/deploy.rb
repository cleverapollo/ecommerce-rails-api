lock '3.4.0'

set :application, 'api.rees46.com'

set :repo_url, 'git@rees46_api.bitbucket.org:mkechinov/rees46_api.git'
set :scm, :git

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :deploy_via,      :remote_cache
set :ssh_options,     {forward_agent: true}
set :use_sudo,        false
set :keep_releases, 20
set :linked_files, %w(config/database.yml config/secrets.yml config/shards.yml config/unicorn.rb config/application.yml)
set :linked_dirs, %w(tmp/sockets tmp/ymls log tmp/pids tmp/cache tmp/sockets vendor/bundle)

set :normalize_asset_timestamps, false

set :rails_env,   'production'
set :default_stage,   'api_00'


set :rollbar_token, '8b197bc247a844278f109dbd06ad2e66'
set :rollbar_env, Proc.new { fetch :stage }
set :rollbar_role, Proc.new { :app }

set :rvm_type, :user
# set :rvm_custom_path, '~/.rvm'  # only needed if not detected
set :rvm_ruby_string, "2.2.3"


# Whenever
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
# set :whenever_command, '~/.rvm/bin/rvm default do bundle exec whenever'
# require 'whenever/capistrano'


# Sidekiq
set :sidekiq_env, 'production'
set :sidekiq_options, '-C config/sidekiq.yml'
set :sidekiq_timeout, 300

namespace :deploy do

  desc 'Start unicorn'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "cd #{current_path}; ~/.rvm/bin/rvm default do bundle exec unicorn -c config/unicorn.rb -E #{fetch :rails_env} -D"
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "kill -s QUIT `cat #{shared_path}/tmp/pids/unicorn.pid`"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "kill -s USR2 `cat #{shared_path}/tmp/pids/unicorn.pid`"
    end
  end

end

require './config/boot'
