lock '3.4.0'

set :application, 'api.rees46.com'

set :repo_url, 'git@rees46_api.bitbucket.org:mkechinov/rees46_api.git'
set :scm, :git

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :deploy_via,      :remote_cache
set :ssh_options,     {forward_agent: true}
set :use_sudo,        false
set :keep_releases, 5
set :linked_files, %w(config/database.yml config/secrets.yml config/shards.yml config/unicorn.rb)
set :linked_dirs, %w(tmp/sockets tmp/ymls log tmp/pids tmp/cache tmp/sockets vendor/bundle)

set :normalize_asset_timestamps, false

set :rails_env,   'production'
set :default_stage,   'production'


set :rvm_type, :user
# set :rvm_custom_path, '~/.rvm'  # only needed if not detected
# set :rvm_ruby_string, "2.2.2"


# Whenever
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
# set :whenever_command, '~/.rvm/bin/rvm default do bundle exec whenever'
require 'whenever/capistrano'


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
      execute "kill -s QUIT `cat #{shared_path}/pids/unicorn.pid`"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "kill -s USR2 `cat #{shared_path}/pids/unicorn.pid`"
    end
  end

end















# set :stages, %w(production api_00)

# Deploy configuration
# set :user, 'rails'
# set :shared_children, shared_children + %w[tmp/sockets tmp/ymls]
# set :shared_configs, %w[database.yml secrets.yml shards.yml]





# Whenever
# set :whenever_identifier, defer { "#{application}_#{rails_env}" }

# Deploy tasks
# namespace :deploy do
#   desc "Zero-downtime restart of Unicorn"
#   task :restart, roles: :app, except: { no_release: true } do
#     run "kill -s USR2 `cat #{shared_path}/pids/unicorn.pid`"
#   end
#
#   desc "Start unicorn"
#   task :start, roles: :app, except: { no_release: true } do
#     run "cd #{current_path}; bundle exec unicorn -c config/unicorn.rb -E #{rails_env} -D"
#   end
#
#   desc "Stop unicorn"
#   task :stop, roles: :app, except: { no_release: true } do
#     run "kill -s QUIT `cat #{shared_path}/pids/unicorn.pid`"
#   end
# end
#
# # Config management
# namespace :config do
#
#   desc "Create symlinks to shared configs"
#   task :symlink, roles: :app do
#     run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
#     run "ln -nfs #{shared_path}/config/secrets.yml #{release_path}/config/secrets.yml"
#     run "ln -nfs #{shared_path}/config/unicorn.rb #{release_path}/config/unicorn.rb"
#   end
#
# end
#
# after 'deploy:finalize_update', 'config:symlink'
# after 'deploy', 'deploy:cleanup'
# after 'deploy:cold', 'deploy:cleanup'

require './config/boot'
