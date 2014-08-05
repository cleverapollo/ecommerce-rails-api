class ItemsSynchronizeWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'critical'

  def perform(item_id, attrs)
    item = Item.find(item_id); attrs.symbolize_keys!

    Item::ARRAY_ATTRIBUTES.each do |key|
      attrs[key] = attrs[key].blank? ? '{}' : "{#{attrs[key].join(',')}}"
    end

    item.actions.find_in_batches(batch_size: 100) do |batch|
      Action.where(id: batch.map(&:id), item_id: item.id, shop_id: item.shop_id).update_all(attrs.select{|key, _| Item::ACTION_ATTRIBUTES.include?(key.to_sym) })
    end
  end
end
