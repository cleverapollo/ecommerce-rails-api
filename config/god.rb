

God.watch do |w|

  ROOT = '/home/rails/rees46_brb/current'

  pid_file = "#{ROOT}/tmp/pids/server.pid"
  rvm_command = "rvm jruby-1.7.20 do bundle exec"
  pid_command = "ps aux | grep 'jruby' | grep -v grep | awk '{print $2}' | head -n1"

  w.name = 'brb'
  w.dir = ROOT

  w.env = {
      'RAILS_ENV' => 'production',
      'JRUBY_OPTS' => '-J-Xmx1512m -J-XX:+CMSClassUnloadingEnabled -J-XX:+UseConcMarkSweepGC -J-Djruby.jit.threshold=0',
      'MAHOUT_DIR' => '/home/rails/rees46_brb/shared/libs/mahout'
  }

  # sleep для того, чтобы сервер успел прогрузиться (иначе будет кривой pid)
  w.start = "cd #{ROOT} && #{rvm_command} bin/server.rb &> #{ROOT}/log/server.txt && sleep 5 && echo $(#{pid_command}) > #{pid_file}"
  w.stop = "kill $(ps aux | grep 'jruby'| grep -v grep | awk '{print $2}')"

  w.pid_file = pid_file
  w.start_grace = 10.seconds

  #w.behavior(:clean_pid_file)

  w.log = "#{ROOT}/log/server_god.log"
  w.keepalive(:interval=>10.seconds)

end




God.watch do |w|
  ROOT = '/home/rails/rees46_cf_daemons/current'
  rvm_command = "rvm ruby-2.2.3 do bundle exec"
  pid_file = "#{ROOT}/tmp/pids/saver.pid"
  w.name = 'cf_events_saver'
  w.start = "cd #{ROOT} && RAILS_ENV=production #{rvm_command} #{ROOT}/bin/cf_events_saver.rb"
  w.stop = "kill -s QUIT $(cat #{pid_file})"
  w.keepalive interval: 10.seconds
  w.log = "/var/log/god/cf_events_saver.log"
  w.env = {
      'RAILS_ENV' => 'production',
  }
  w.pid_file = pid_file
  w.behavior(:clean_pid_file)
end



God.watch do |w|
  ROOT = '/home/rails/rees46_cf_daemons/current'
  rvm_command = "rvm ruby-2.2.3 do bundle exec"
  pid_file = "#{ROOT}/tmp/pids/relink.pid"
  w.name = 'cf_user_relink'
  w.start = "cd #{ROOT} && RAILS_ENV=production #{rvm_command} #{ROOT}/bin/cf_user_relink.rb"
  w.stop = "kill -s QUIT $(cat #{pid_file})"
  w.keepalive interval: 10.seconds
  w.log = "/var/log/god/cf_user_relink.log"
  w.env = {
      'RAILS_ENV' => 'production',
  }
  w.pid_file = pid_file
  w.behavior(:clean_pid_file)
end
