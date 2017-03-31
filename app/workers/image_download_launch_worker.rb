class ImageDownloadLaunchWorker
  require 'bunny'
  include Sidekiq::Worker

  sidekiq_options retry: false, queue: 'resize'

  class ImageDownloadLaunchError < StandardError; end

  BATCH_SIZE = 50

  def perform(shop_id, items_images = nil, delete_before_download =  false)
    @shop = Shop.find(shop_id)
    @delete_before_download = delete_before_download
    connect!

    if items_images
      send_batch(items_images)
    else
      fetch_and_send_baches
    end

    @connection.close
  end

  private

  def initialized_connection
    return Bunny.new unless Rails.env.production?
    Bunny.new(host: '148.251.91.107', user: 'rees46', pass: Rails.application.secrets.bunny_password)
  end

  def connect!
    @connection = initialized_connection
    @connection.start
    @channel = @connection.create_channel
    @queue = @channel.queue('resize', durable: true)
  end

  def fetch_and_send_baches
    items_images = []

    Item.recommendable.widgetable.where(shop_id: @shop.id).select(:id, :image_url).find_each do |item|
      items_images << { id: item.id, image_url: item.image_url }

      if items_images.size == BATCH_SIZE
        send_batch(items_images)
        items_images = []
      end
    end

    send_batch(items_images)
  end

  def send_batch(items_images)
    @channel.default_exchange.publish({ shop_uniqid: @shop.uniqid,
                                        items_images: items_images,
                                        delete_before_download: @delete_before_download
                                      }.to_json,
                                      durable: true,
                                      routing_key: @queue.name)
  end
end
