role :app, %w{94.130.90.232}
role :web, %w{94.130.90.232}
role :db,  %w{94.130.90.232}

set :application, 'api.personaclick.com'
set :stage, :personaclick

set :log_level,   :info

set :ssh_options, {
    user: 'rails',
    forward_agent: true,
    port: 21212
}

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :branch, 'master'
set :rails_env, 'production'

Rake::Task['deploy:start'].clear_actions
Rake::Task['deploy:stop'].clear_actions
Rake::Task['deploy:restart'].clear_actions
namespace :deploy do

  desc 'Start unicorn'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo /usr/bin/supervisorctl start api"
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo /usr/bin/supervisorctl stop api"
    end
  end
end