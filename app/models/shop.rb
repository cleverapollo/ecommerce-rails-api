class Shop < ActiveRecord::Base
  store :connection_status, accessors: [:connected_events, :connected_recommenders], coder: JSON

  has_many :user_shop_relations
  has_many :items

  def available_item_ids
    items.available.pluck(:id)
  end
end
