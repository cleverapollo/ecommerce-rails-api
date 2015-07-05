# require 'whenever/capistrano'

set :stages, %w(production api_00)
set :default_stage, "production"

set :rvm_ruby_string, "2.2.1"

# Deploy configuration
set :user, 'rails'
set :use_sudo, false
set :shared_children, shared_children + %w[tmp/sockets tmp/ymls]
set :shared_configs, %w[database.yml secrets.yml]

# VCS Configuration
set :scm, :git
set :repository, 'git@rees46_api.bitbucket.org:mkechinov/rees46_api.git'
set :deploy_via, :remote_cache
set :ssh_options, forward_agent: true

# Releases Config
set :keep_releases, 5

set :normalize_asset_timestamps, false

# Sidekiq
# set :sidekiq_env, 'production'
# set :sidekiq_options, '-C config/sidekiq.yml'
# set :sidekiq_timeout, 300

# Whenever
set :whenever_identifier, defer { "#{application}_#{rails_env}" }

# Deploy tasks
namespace :deploy do
  desc "Zero-downtime restart of Unicorn"
  task :restart, roles: :app, except: { no_release: true } do
    run "kill -s USR2 `cat #{shared_path}/pids/unicorn.pid`"
  end

  desc "Start unicorn"
  task :start, roles: :app, except: { no_release: true } do
    run "cd #{current_path}; bundle exec unicorn -c config/unicorn.rb -E #{rails_env} -D"
  end

  desc "Stop unicorn"
  task :stop, roles: :app, except: { no_release: true } do
    run "kill -s QUIT `cat #{shared_path}/pids/unicorn.pid`"
  end
end

# Config management
namespace :config do

  desc "Create symlinks to shared configs"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/secrets.yml #{release_path}/config/secrets.yml"
    run "ln -nfs #{shared_path}/config/unicorn.rb #{release_path}/config/unicorn.rb"
  end

end

after 'deploy:finalize_update', 'config:symlink'
after 'deploy', 'deploy:cleanup'
after 'deploy:cold', 'deploy:cleanup'

require './config/boot'
