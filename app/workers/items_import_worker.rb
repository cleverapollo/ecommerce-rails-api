# Импорт товаров

class ItemsImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    fetch_and_authenticate_shop(params.fetch('shop_id'), params.fetch('shop_secret'))
    process_items(params.fetch('items'))
  end

  def fetch_and_authenticate_shop(uniqid, secret)
    @shop = Shop.find_by!(uniqid: uniqid, secret: secret)
  end

  def process_items(items)
    items.map do |item_params|
      item_struct = OpenStruct.new(item_params)
      item_struct.uniqid = item_params.fetch('id')
      item_struct.category_ids = item_params['categories']
      item_struct.amount = 0
      item_struct
    end.each do |item_struct|
      Item.fetch(shop.id, item_struct)
    end
  end
end
