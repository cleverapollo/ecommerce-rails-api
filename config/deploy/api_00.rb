role :app, %w{5.9.48.142}
role :web, %w{5.9.48.142}
role :db,  %w{5.9.48.142}

set :stage, :api_00
set :shard, :api_00

set :log_level,   :info

set :ssh_options, {
    user: 'rails',
    forward_agent: true,
    port: 21212
}

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :branch, 'master'
set :rails_env, 'production'