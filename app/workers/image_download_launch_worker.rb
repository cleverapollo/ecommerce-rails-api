class ImageDownloadLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'resize'

  class ImageDownloadLaunchError < StandardError; end

  BATCH_SIZE = 50

  def perform(shop_id, items_images = nil, delete_before_download =  false)
    @shop = Shop.find(shop_id)
    @delete_before_download = delete_before_download
    if items_images
      send_batch(items_images)
    else
      fetch_and_send_baches
    end
  end

  private

  def fetch_and_send_baches
    items_images = []

    Item.where(shop_id: @shop.id).available.recommendable.widgetable.select(:id, :image_url).find_each do |item|
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

    conn = if Rails.env.production?
      Bunny.new(host: "148.251.91.107", user: 'rees46', pass: Rails.application.secrets.bunny_password)
    else
      Bunny.new
    end
    conn.start

    ch = conn.create_channel

    q = ch.queue("resize", durable: true)
    ch.default_exchange.publish({ shop_uniqid: @shop.uniqid, items_images: items_images, delete_before_download: @delete_before_download }.to_json, durable: true, :routing_key => q.name)

    conn.close
  end

end
