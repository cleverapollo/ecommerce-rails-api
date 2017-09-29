class ClickhouseQueue

  class << self

    # Добавление в очередь событий
    # todo сделать mock
    # @param [String] table
    # @param [Hash] values
    def push(table, values = {})
      queue.publish({
          table: table,
          values: values
      }.to_json) if Rails.env.production?
    end

    # @param [Hash] values
    def order_items(values = {})
      push('order_items', values)
    end

    protected

    # @return [Bunny::Session]
    def connection
      @connection ||= Bunny.new(host: Rails.application.secrets.bunny_host, user: Rails.application.secrets.bunny_user, pass: Rails.application.secrets.bunny_password).start
    end

    # @return [Bunny::Channel]
    def channel
      @channel ||= connection.create_channel
    end

    def queue
      @queue ||= channel.queue('clickhouse', durable: true)
    end

  end

end
