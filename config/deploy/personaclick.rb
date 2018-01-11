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

# Whenever
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

Rake::Task['deploy:start'].clear_actions
Rake::Task['deploy:stop'].clear_actions
Rake::Task['deploy:restart'].clear_actions
Rake::Task['sidekiq:start'].clear_actions
Rake::Task['sidekiq:stop'].clear_actions
Rake::Task['sidekiq:restart'].clear_actions


namespace :sidekiq do
  task :start do
    on roles(:app), in: :sequence, wait: 5 do

      execute 'sudo /usr/bin/supervisorctl start api-sidekiq-yaml'
      execute 'sudo /usr/bin/supervisorctl start api-sidekiq'
      execute 'sudo /usr/bin/supervisorctl start api-sidekiq-mailing1'
      execute 'sudo /usr/bin/supervisorctl start api-sidekiq-mailing2'
    end
  end
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo /usr/bin/supervisorctl stop api-sidekiq-yaml'
      execute 'sudo /usr/bin/supervisorctl stop api-sidekiq'
      execute 'sudo /usr/bin/supervisorctl stop api-sidekiq-mailing1'
      execute 'sudo /usr/bin/supervisorctl stop api-sidekiq-mailing2'
    end
  end
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo /usr/bin/supervisorctl restart api-sidekiq-yaml'
      execute 'sudo /usr/bin/supervisorctl restart api-sidekiq'
      execute 'sudo /usr/bin/supervisorctl restart api-sidekiq-mailing1'
      execute 'sudo /usr/bin/supervisorctl restart api-sidekiq-mailing2'
    end
  end
end

namespace :deploy do

  desc 'Start unicorn'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      # execute "sudo /usr/bin/supervisorctl start api"
    end
  end
  desc 'Restart unicorn'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # execute "sudo /usr/bin/supervisorctl restart api"
    end
  end
  desc 'Stop unicorn'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      # execute "sudo /usr/bin/supervisorctl stop api"
    end
  end
end
after 'deploy:restart', 'sidekiq:restart'

