lock '3.7.2'

set :application, 'api.rees46.com'

set :repo_url, 'git@rees46_api.bitbucket.org:mkechinov/rees46_api.git'
# set :scm, :git

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :deploy_via,      :remote_cache
set :ssh_options,     {forward_agent: true}
set :use_sudo,        false
set :keep_releases, 20
set :linked_files, %w(config/database.yml config/secrets.yml config/unicorn.rb config/application.yml)
set :linked_dirs, %w(tmp/sockets tmp/ymls log tmp/pids tmp/cache vendor/bundle tmp/optivo_mytoys nginx_mapping tmp/safari_keys)

set :normalize_asset_timestamps, false

set :rails_env,   'production'
set :default_stage,   'api_00'

set :rollbar_token, '8b197bc247a844278f109dbd06ad2e66'
set :rollbar_env, Proc.new { fetch :stage }
set :rollbar_role, Proc.new { :app }

set :rvm_type, :user
# set :rvm_custom_path, '~/.rvm'  # only needed if not detected
set :rvm_ruby_string, '2.3.0'

# Whenever
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
# set :whenever_command, '~/.rvm/bin/rvm default do bundle exec whenever'
# require 'whenever/capistrano'


# Sidekiq
# set :sidekiq_env, 'production'
# set :sidekiq_options, '-C config/sidekiq.yml'
# set :sidekiq_timeout, 300

after 'deploy:publishing', 'deploy:restart'


namespace :sidekiq do
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo /bin/systemctl start sidekiq.api.rees46.yml.service'
      # execute 'sudo /bin/systemctl start sidekiq.api.rees46.mailing1.service'
      # execute 'sudo /bin/systemctl start sidekiq.api.rees46.mailing2.service'
      execute 'sudo /bin/systemctl start sidekiq.api.rees46.service'
    end
  end
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo /bin/systemctl stop sidekiq.api.rees46.yml.service'
      # execute 'sudo /bin/systemctl stop sidekiq.api.rees46.mailing1.service'
      # execute 'sudo /bin/systemctl stop sidekiq.api.rees46.mailing2.service'
      execute 'sudo /bin/systemctl stop sidekiq.api.rees46.service'
    end
  end
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sudo /bin/systemctl restart sidekiq.api.rees46.yml.service'
      # execute 'sudo /bin/systemctl restart sidekiq.api.rees46.mailing1.service'
      # execute 'sudo /bin/systemctl restart sidekiq.api.rees46.mailing2.service'
      execute 'sudo /bin/systemctl restart sidekiq.api.rees46.service'
    end
  end
end


namespace :deploy do

  desc 'Start unicorn'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo /bin/systemctl start unicorn.api.rees46.service"
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo /bin/systemctl stop unicorn.api.rees46.service"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo /bin/systemctl restart unicorn.api.rees46.service"
    end
  end

  desc 'Reload application'
  task :reload do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo /bin/systemctl reload unicorn.api.rees46.service"
    end
  end


  # desc 'Start unicorn'
  # task :start do
  #   on roles(:app), in: :sequence, wait: 5 do
  #     execute "cd #{current_path}; ~/.rvm/bin/rvm default do bundle exec unicorn -c config/unicorn.rb -E #{fetch :rails_env} -D"
  #   end
  # end
  #
  # desc 'Stop unicorn'
  # task :stop do
  #   on roles(:app), in: :sequence, wait: 5 do
  #     execute "kill -s QUIT `cat #{shared_path}/tmp/pids/unicorn.pid`"
  #   end
  # end
  #
  # desc 'Restart application'
  # task :restart do
  #   on roles(:app), in: :sequence, wait: 5 do
  #     execute "kill -s USR2 `cat #{shared_path}/tmp/pids/unicorn.pid`"
  #   end
  # end


end


# before 'deploy:stop', 'sidekiq:stop'
# after 'deploy:start', 'sidekiq:start'
after 'deploy:restart', 'sidekiq:restart'


SSHKit.config.command_map[:god] = "~/.rvm/bin/rvm 2.3.0 do god"

namespace :god do
  task :start do
    on roles(:app) do
      execute :god
    end
  end

  task :load_config do
    on roles(:app) do
      execute :god, "load #{File.join deploy_to, 'current', 'config', 'god.rb'}"
    end
  end

  task :quit do
    on roles(:app) do
      execute :god, 'quit'
    end
  end

  task :cf_start do
    on roles(:app) do
      execute :god, 'start cf'
    end
  end

  task :cf_stop do
    on roles(:app) do
      execute :god,'stop cf'
    end
  end

end

