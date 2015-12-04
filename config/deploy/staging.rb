role :app, %w{5.101.116.131}
role :web, %w{5.101.116.131}
role :db,  %w{5.101.116.131}

set :stage, :stage
set :shard, :stage

set :log_level, :info

set :ssh_options, {
  user: 'rails',
  forward_agent: true,
  port: 21212
}

set :deploy_to, "/home/rails/staging.rees46.com"
set :branch, 'develop'
set :rails_env, 'staging'
set :sidekiq_env, 'staging'