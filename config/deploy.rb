lock '3.4.0'

set :application, 'api.rees46.com'

set :repo_url, 'git@rees46_api.bitbucket.org:mkechinov/rees46_api.git'
set :scm, :git

set :deploy_to, "/home/rails/#{fetch(:application)}"
set :deploy_via,      :remote_cache
set :ssh_options,     {forward_agent: true}
set :use_sudo,        false
set :keep_releases, 20
set :linked_files, %w(config/database.yml config/secrets.yml config/unicorn.rb config/application.yml config/mongoid.yml)
set :linked_dirs, %w(tmp/sockets tmp/ymls log tmp/pids tmp/cache vendor/bundle tmp/optivo_mytoys nginx_mapping)

set :normalize_asset_timestamps, false

set :rails_env,   'production'
set :default_stage,   'api_00'

set :rollbar_token, '8b197bc247a844278f109dbd06ad2e66'
set :rollbar_env, Proc.new { fetch :stage }
set :rollbar_role, Proc.new { :app }

set :rvm_type, :user
# set :rvm_custom_path, '~/.rvm'  # only needed if not detected
set :rvm_ruby_string, "2.2.3"

# Whenever
# set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
# set :whenever_command, '~/.rvm/bin/rvm default do bundle exec whenever'
# require 'whenever/capistrano'


# Sidekiq
set :sidekiq_env, 'production'
set :sidekiq_options, '-C config/sidekiq.yml'
set :sidekiq_timeout, 300

after 'deploy:publishing', 'deploy:restart'

namespace :deploy do
  desc 'Start unicorn'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "cd #{current_path}; ~/.rvm/bin/rvm default do bundle exec unicorn -c config/unicorn.rb -E #{fetch :rails_env} -D"
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "kill -s QUIT `cat #{shared_path}/tmp/pids/unicorn.pid`"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "kill -s USR2 `cat #{shared_path}/tmp/pids/unicorn.pid`"
    end
  end
end

namespace :yml do
  task :import do
    on roles(:app) do
      within current_path do
        with rails_env: :production do
          execute :rake, "yml:process_all"
        end
      end
    end
  end
end



SSHKit.config.command_map[:god] = "~/.rvm/bin/rvm 2.2.3 do god"

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

  task :brb_start do
    on roles(:app) do
      execute :god, 'start brb'
    end
  end

  task :brb_stop do
    on roles(:app) do
      #execute :ruby,'-v'
      execute :god,'stop brb'
    end
  end

  task :saver_start do
    on roles(:app) do
      execute :god, 'start cf_events_saver'
    end
  end

  task :saver_stop do
    on roles(:app) do
      #execute :ruby,'-v'
      execute :god,'stop cf_events_saver'
    end
  end

  task :relink_start do
    on roles(:app) do
      execute :god, 'start cf_user_relink'
    end
  end

  task :relink_stop do
    on roles(:app) do
      #execute :ruby,'-v'
      execute :god,'stop cf_user_relink'
    end
  end


end

