FROM djeshkov/rails46_api:build
COPY . /home/rails/api/current
RUN chown -R rails /home/rails
USER rails
RUN cd /home/rails/api/current && bash -l -c 'bundler'
USER root
ENTRYPOINT []
WORKDIR /home/rails/api/current
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n

