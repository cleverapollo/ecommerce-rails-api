role :app, %w{5.45.118.36}
role :web, %w{5.45.118.36}
role :db,  %w{5.45.118.36}

set :stage, :api_00
set :shard, :api_00

set :log_level,   :info

set :ssh_options, {
    user: 'rails',
    forward_agent: true,
    port: 21212
}

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :branch, 'split_db'
set :rails_env, 'production'