role :app, %w{88.99.193.211}
role :web, %w{88.99.193.211}
role :db,  %w{88.99.193.211}

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

Rake::Task['sidekiq:start'].clear_actions
Rake::Task['sidekiq:stop'].clear_actions
Rake::Task['sidekiq:restart'].clear_actions
namespace :sidekiq do
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo /bin/systemctl start sidekiq.api.rees46.yml.service'
      execute 'sudo /bin/systemctl start sidekiq.api.rees46.mailing1.service'
      execute 'sudo /bin/systemctl start sidekiq.api.rees46.mailing2.service'
      execute 'sudo /bin/systemctl start sidekiq.api.rees46.mailing3.service'
      execute 'sudo /bin/systemctl start sidekiq.api.rees46.trigger.service'
      execute 'sudo /bin/systemctl start sidekiq.api.rees46.service'

      # execute 'sudo /usr/bin/supervisorctl start api.rees46.yml.service'
      # execute 'sudo /usr/bin/supervisorctl start api-sidekiq-mailing1'
      # execute 'sudo /usr/bin/supervisorctl start api-sidekiq-mailing2'
      # execute 'sudo /usr/bin/supervisorctl start api-sidekiq-mailing3'
      # execute 'sudo /usr/bin/supervisorctl start api-trigger'
      # execute 'sudo /usr/bin/supervisorctl start api-sidekiq'
    end
  end
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo /bin/systemctl stop sidekiq.api.rees46.yml.service'
      execute 'sudo /bin/systemctl stop sidekiq.api.rees46.mailing1.service'
      execute 'sudo /bin/systemctl stop sidekiq.api.rees46.mailing2.service'
      execute 'sudo /bin/systemctl stop sidekiq.api.rees46.mailing3.service'
      execute 'sudo /bin/systemctl stop sidekiq.api.rees46.trigger.service'
      execute 'sudo /bin/systemctl stop sidekiq.api.rees46.service'

      # execute 'sudo /usr/bin/supervisorctl stop api.rees46.yml.service'
      # execute 'sudo /usr/bin/supervisorctl stop api-sidekiq-mailing1'
      # execute 'sudo /usr/bin/supervisorctl stop api-sidekiq-mailing2'
      # execute 'sudo /usr/bin/supervisorctl stop api-sidekiq-mailing3'
      # execute 'sudo /usr/bin/supervisorctl stop api-trigger'
      # execute 'sudo /usr/bin/supervisorctl stop api-sidekiq'
    end
  end
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo /bin/systemctl restart sidekiq.api.rees46.yml.service'
      execute 'sudo /bin/systemctl restart sidekiq.api.rees46.mailing1.service'
      execute 'sudo /bin/systemctl restart sidekiq.api.rees46.mailing2.service'
      execute 'sudo /bin/systemctl restart sidekiq.api.rees46.mailing3.service'
      execute 'sudo /bin/systemctl restart sidekiq.api.rees46.trigger.service'
      execute 'sudo /bin/systemctl restart sidekiq.api.rees46.service'

      # execute 'sudo /usr/bin/supervisorctl restart api.rees46.yml.service'
      # execute 'sudo /usr/bin/supervisorctl restart api-sidekiq-mailing1'
      # execute 'sudo /usr/bin/supervisorctl restart api-sidekiq-mailing2'
      # execute 'sudo /usr/bin/supervisorctl restart api-sidekiq-mailing3'
      # execute 'sudo /usr/bin/supervisorctl restart api-trigger'
      # execute 'sudo /usr/bin/supervisorctl restart api-sidekiq'
    end
  end
end
after 'deploy:restart', 'sidekiq:restart'
