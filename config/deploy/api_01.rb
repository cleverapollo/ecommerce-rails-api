role :app, %w{88.99.193.175}
role :web, %w{88.99.193.175}
role :db,  %w{88.99.193.175}

set :stage, :api_01
set :shard, :api_01

set :log_level,   :info

set :ssh_options, {
    user: 'rails',
    forward_agent: true,
    port: 21212
}

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :branch, 'master'
set :rails_env, 'production'