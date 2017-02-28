role :app, %w{185.16.102.217}
role :web, %w{185.16.102.217}
role :db,  %w{185.16.102.217}

role :production_cron, %w{185.16.102.217}


set :stage, :staging
set :shard, ENV['shard'] || '00'

set :log_level, :info

set :ssh_options, {
  user: 'rails',
  forward_agent: true,
  port: 20001
}

set :deploy_to, "/home/rails/stage#{fetch(:shard)}.api.rees46.com"
set :rails_env, 'staging'
set :sidekiq_env, 'staging'
set :branch, 'master'


Rake::Task['whenever:update_crontab'].clear_actions
namespace :whenever do
  task :update_crontab do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'echo Disable for staging'
    end
  end
end

Rake::Task['deploy:start'].clear_actions
Rake::Task['deploy:stop'].clear_actions
Rake::Task['deploy:restart'].clear_actions
namespace :deploy do

  desc 'Start unicorn'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo /bin/systemctl start unicorn.stage#{fetch(:shard)}.api.rees46.service"
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo /bin/systemctl stop unicorn.stage#{fetch(:shard)}.api.rees46.service"
    end
  end
end