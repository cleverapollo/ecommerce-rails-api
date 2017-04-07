if Rails.env.production?
  require 'clickhouse'
  Clickhouse.establish_connection host: Rails.application.secrets.clickhouse_host
end
