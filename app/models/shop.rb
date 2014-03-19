class Shop < ActiveRecord::Base
  store :connection_status, accessors: [:connected_events, :connected_recommenders], coder: JSON

  has_and_belongs_to_many :users
  has_many :shops_users

  has_many :user_shop_relations
  has_many :items

  def available_item_ids
    items.available.pluck(:id)
  end
end
