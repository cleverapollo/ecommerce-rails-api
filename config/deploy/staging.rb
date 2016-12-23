role :app, %w{217.195.83.92}
role :web, %w{217.195.83.92}
role :db,  %w{217.195.83.92}

role :production_cron, %w{217.195.83.92}


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
set :branch, 'develop'


Rake::Task['whenever:update_crontab'].clear_actions
namespace :whenever do
  task :update_crontab do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'echo Disable for staging'
    end
  end
end
