##
# Корзины и покупки. Используются в коллаборативке
# @deprecated
##
class MahoutAction

  MAHOUT_QUEUE_RELINK_USER = 'rees46.cf.relink_user'

  class << self

    def publish_to_mahout(message)
      q  = channel_to_mahout.queue MAHOUT_QUEUE_RELINK_USER
      x  = channel_to_mahout.default_exchange
      x.publish message, :routing_key => q.name
    end

    def connection_to_mahout
      @connection_to_mahout ||= Bunny.new.tap do |c|
        c.start
      end
    end

    def channel_to_mahout
      @channel_to_mahout ||= connection_to_mahout.create_channel
    end



    def relink_user(options = {})

      MahoutAction.publish_to_mahout [options.fetch(:from).id, options.fetch(:to).id].join(',')

      # mahout_service = MahoutService.new
      # mahout_service.open
      # mahout_service.relink_user(options.fetch(:from).id, options.fetch(:to).id)
      # mahout_service.close
    end
  end

end
