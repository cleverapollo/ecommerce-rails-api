class ElasticSearchConnector
  class << self

    attr_accessor :connection

    def get_connection
      self.connection ||= Elasticsearch::Client.new(hosts: [
            {
                host: Rails.application.secrets.elastic_host,
                port: Rails.application.secrets.elastic_port,
                user: Rails.application.secrets.elastic_user ? Rails.application.secrets.elastic_user : nil,
                password: Rails.application.secrets.elastic_pass ? Rails.application.secrets.elastic_pass : nil,
                scheme: Rails.application.secrets.elastic_protocol,
            }
        ],
        reload_on_failure: true,
        log: !Rails.env.production?
      )
    end
  end
end