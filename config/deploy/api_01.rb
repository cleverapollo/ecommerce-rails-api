role :app, %w{88.99.144.96}
role :web, %w{88.99.144.96}
role :db,  %w{88.99.144.96}

set :stage, :api_01
set :shard, :api_01

set :log_level,   :info

set :ssh_options, {
    user: 'rails',
    forward_agent: true,
    port: 22
}

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :branch, 'master'
set :rails_env, 'production'