role :app, %w{178.63.14.3}
role :web, %w{178.63.14.3}
role :db,  %w{178.63.14.3}

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

# Запрещено инициализировать крон таски
Rake::Task['whenever:update_crontab'].clear_actions
namespace :whenever do
  task :update_crontab do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'echo Disable for 02'
    end
  end
end

Rake::Task['sidekiq:start'].clear_actions
Rake::Task['sidekiq:stop'].clear_actions
Rake::Task['sidekiq:restart'].clear_actions
namespace :sidekiq do
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'echo disable for 02'
    end
  end
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'echo disable for 02'
    end
  end
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'echo disable for 02'
    end
  end
end
