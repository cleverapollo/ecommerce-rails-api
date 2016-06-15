role :app, %w{148.251.76.233}
role :web, %w{148.251.76.233}
role :db,  %w{148.251.76.233}

set :stage, :api_02
set :shard, :api_02

set :log_level,   :info

set :ssh_options, {
    user: 'rails',
    forward_agent: true,
    port: 21212
}

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :branch, 'master'
set :rails_env, 'production'
