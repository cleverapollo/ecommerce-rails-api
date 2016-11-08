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
    params = { shop_id: shop.id, items_images: items_images }
    ImageDownloaderWorker.perform_async(params)
  end
end
