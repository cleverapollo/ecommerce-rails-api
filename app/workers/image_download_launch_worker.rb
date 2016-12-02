class ImageDownloadLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'resize'

  class ImageDownloadLaunchError < StandardError; end

  BATCH_SIZE = 20

  attr_reader :shop

  def perform(shop_id)
    @shop = Shop.find(shop_id)

    items_images = []
    Item.where(shop_id: shop.id).widgetable.each do |item|
      items_images << { id: item.id, image_url: item.image_url }

      if items_images.size == BATCH_SIZE
        send_batch(items_images)
        items_images = []
      end
    end
    send_batch(items_images)
  end

  def send_batch(items_images)
    require "bunny"
    conn = Bunny.new(host: "148.251.91.107", user: 'rees46', pass: Rails.application.secrets.bunny_password)
    conn.start

    ch = conn.create_channel

    q = ch.queue("resize", durable: true)
    ch.default_exchange.publish({ shop_uniqid: shop.uniqid, items_images: items_images }.to_json, durable: true, :routing_key => q.name)

    conn.close
  end
end
