class ClickhouseQueue

  class << self

    # Добавление в очередь событий
    # todo сделать mock
    # @param [String] table
    # @param [Hash] values
    def push(table, values = {}, opts = {})
      queue.publish(JSON.generate({
          table: table,
          values: values,
          opts: opts,
      })) unless Rails.env.test?
    end

    # @param [Hash] values
    def order_items(values = {}, opts = {})
      push('order_items', values, opts)
    end

    # @param [Hash] values
    def actions(values)
      push('actions', values)
    end

    # @param [Hash] values
    def recone_actions(values)
      push('recone_actions', values)
    end

    # @return [Bunny::Session]
    def connection
      @connection ||= Bunny.new(host: Rails.application.secrets.bunny_host, user: Rails.application.secrets.bunny_user, pass: Rails.application.secrets.bunny_password).start
    end

    protected

    # @return [Bunny::Channel]
    def channel
      @channel ||= connection.create_channel
    end

    def queue
      @queue ||= channel.queue('clickhouse', durable: true)
    end

  end

end
