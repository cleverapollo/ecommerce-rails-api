FROM registry.jeshkov.ru:5000/jeshkov.ru/puppet/environment_ketchinov/rails46_api:run
ADD . /home/rails/api.rees46.com/current
RUN chown -R rails /home/rails
USER rails
RUN mkdir -p /home/rails/api.rees46.com/shared/tmp/ && mkdir /home/rails/api.rees46.com/shared/tmp/sockets && mkdir /home/rails/api.rees46.com/shared/log && mkdir /home/rails/api.rees46.com/shared/tmp/pids
USER root
ENTRYPOINT []
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n


