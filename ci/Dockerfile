FROM registry.jeshkov.ru:5000/jeshkov.ru/puppet/environment_ketchinov/rails46_api:build
ADD . /home/rails/api.rees46.com/current
RUN chown -R rails /home/rails
RUN pip install unicornherder
USER rails
RUN mkdir -p /home/rails/api.rees46.com/shared/tmp/ && mkdir /home/rails/api.rees46.com/shared/tmp/sockets && mkdir /home/rails/api.rees46.com/shared/log && mkdir /home/rails/api.rees46.com/shared/tmp/pids
RUN /home/rails/.rvm/bin/rvm all do gem install bundler
RUN cd /home/rails/api.rees46.com/current && /home/rails/.rvm/bin/rvm all do bundle
USER root
RUN rm /var/run/supervisor*
ENTRYPOINT []
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n


