role :app, %w{144.76.98.71}
role :web, %w{144.76.98.71}
role :db,  %w{144.76.98.71}

set :stage, :api_03
set :shard, :api_03

set :log_level,   :info

set :ssh_options, {
    user: 'rails',
    forward_agent: true,
    port: 21212
}

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :branch, 'master'
set :rails_env, 'production'
