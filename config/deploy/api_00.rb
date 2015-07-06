role :app, %w{5.101.116.131}
role :web, %w{5.101.116.131}
role :db,  %w{5.101.116.131}

set :stage, :api_00

set :log_level,   :info

set :ssh_options, {
    user: 'commerce',
    forward_agent: true,
    port: 21212
}

set :application, 'api.rees46.com'
set :deploy_to, "/home/rails/#{application}"
set :branch, 'split_db'
set :rails_env, 'production'