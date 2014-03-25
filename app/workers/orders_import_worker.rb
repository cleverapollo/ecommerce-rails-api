class OrdersImportWorker
  include Sidekiq::Worker

  attr_accessor :shop
  attr_accessor :current_order
  attr_accessor :current_user
  attr_accessor :processed_items

  def perform(shop_id, orders)
    self.shop = Shop.find(shop_id)

    orders.each do |order|
      self.current_order = HashWithIndifferentAccess.new(order)
      self.current_user = UserFetcher.new(shop_id: shop.id, uniqid: current_order[:user_id]).fetch
      process_order
    end
  end

  def process_order
    self.processed_items = []
    current_order[:items].each do |item|
      processed_items << process_item(item)
    end

    ActionPush::Processor.new(action_processor_params).process
  end

  def action_processor_params
    OpenStruct.new \
                   action: 'purchase',
                   user: current_user,
                   shop: shop,
                   items: processed_items,
                   date: current_order[:date],
                   order_id: current_order[:id]
  end

  def process_item(item)
    item_proxy = OpenStruct.new \
                   category_uniqid: item[:category_id],
                   price: item[:price],
                   amount: item[:amount],
                   is_available: item[:is_available],
                   uniqid: item[:id]

    Item.fetch(shop.id, item_proxy)
  end
end
