# Воркер который ставит флаг widgetable: false и
# пишет по какой причине не смогли скачать картинку
#
class ItemRestricterWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(params)
    shop = Shop.find_by(uniqid: params['shop_id'])

    item = shop.items.find_by_id(params['item_id'])
    item.update(widgetable: false, image_downloading_error: params['reason']) if item
  end
end
