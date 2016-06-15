role :app, %w{138.201.157.93}
role :web, %w{138.201.157.93}
role :db,  %w{138.201.157.93}

set :stage, :api_99
set :shard, :api_99

set :log_level,   :info

set :ssh_options, {
    user: 'rails',
    forward_agent: true,
    port: 21212
}

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :branch, 'master'
set :rails_env, 'production'
