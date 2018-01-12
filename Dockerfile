FROM rees46com/api:builded_with_puppet
COPY . /home/rails/api/current
RUN chown -R rails /home/rails
RUN pip install unicornherder
USER rails
RUN mkdir -p /home/rails/api/shared/tmp/ && mkdir /home/rails/api/shared/tmp/sockets && mkdir /home/rails/api/shared/log && mkdir /home/rails/api/shared/tmp/pids
RUN mkdir -p "${HOME}/.ssh"
RUN cp "${HOME}/api/current/keyfile.rsa" "${HOME}/.ssh/id_rsa"
RUN chmod 600 "${HOME}/.ssh/id_rsa"
RUN cd /home/rails/api/current && bash -l -c 'bundler'
USER root
ENTRYPOINT []
WORKDIR /home/rails/api/current
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n

