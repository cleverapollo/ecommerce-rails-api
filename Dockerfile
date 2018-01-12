FROM rees46com/api:builded_with_puppet
COPY . /home/rails/api/current
RUN chown -R rails /home/rails
USER rails
RUN mkdir -p "${HOME}/.ssh"
RUN cp "${HOME}/api/current/keyfile.rsa" "${HOME}/.ssh/id_rsa"
RUN chmod 600 "${HOME}/.ssh/id_rsa"
RUN cd /home/rails/api/current && bash -l -c 'bundler'
USER root
ENTRYPOINT []
WORKDIR /home/rails/api/current
CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n

