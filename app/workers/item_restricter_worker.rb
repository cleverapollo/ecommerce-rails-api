# Воркер который ставит флаг widgetable: false и
# пишет по какой причине не смогли скачать картинку
#
class ItemRestricterWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(params)
    shop = Shop.find_by(uniqid: params['shop_id'])
    failed_images = JSON.parse(params['items'])

    failed_images.keys.each do |key|
      shop.items.where(id: failed_images[key]).update_all(widgetable: false, image_downloading_error: key)
    end
  end
end
