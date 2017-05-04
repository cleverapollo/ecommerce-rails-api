role :app, %w{148.251.91.107}
role :web, %w{148.251.91.107}
role :db,  %w{148.251.91.107}

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
set :linked_files, %w(config/database.yml config/secrets.yml config/application.yml)

# Запрощено запускать юникорн
Rake::Task['deploy:start'].clear_actions
Rake::Task['deploy:stop'].clear_actions
Rake::Task['deploy:restart'].clear_actions
Rake::Task['deploy:reload'].clear_actions
namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'echo Deploy restarted'
    end
  end

end