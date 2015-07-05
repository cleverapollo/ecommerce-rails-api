

ssh_options[:port] = 21212

set :application, 'rees46_api'
set :deploy_to, "/home/rails/#{application}"
set :branch, 'master'
set :rails_env, 'production'

set :domain_name, '5.45.118.36'
server domain_name, :web, :app, :db, primary: true, port: 21212
