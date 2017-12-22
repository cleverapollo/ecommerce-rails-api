FROM registry.jeshkov.ru/jeshkov.ru/puppet/environment_ketchinov/rails46_api:run
ADD . /home/rails/api.rees46.com/current
RUN chown -R rails /home/rails/api.rees46.com
USER rails
RUN cd /home/rails/api.rees46.com/current && bash -l -c 'bundler'
USER root
ENTRYPOINT []
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n


