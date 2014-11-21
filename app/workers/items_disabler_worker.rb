class ItemsDisablerWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'critical'

  attr_reader :shop

  def perform(params)
    fetch_and_authenticate_shop(params.fetch('shop_id'), params.fetch('shop_secret'))
    process_items(params.fetch('item_ids'))
  end

  def fetch_and_authenticate_shop(uniqid, secret)
    @shop = Shop.find_by!(uniqid: uniqid, secret: secret)
  end

  def process_items(item_ids)
    item_ids.split(',').each do |item_id|
      if item = shop.items.find_by(uniqid: item_id)
        item.update(is_available: false)
        item.actions.find_in_batches(batch_size: 100) do |batch|
          Action.where(id: batch.map(&:id), item_id: item.id, shop_id: shop.id).update_all(is_available: false)
        end
      end
    end
  end
end
