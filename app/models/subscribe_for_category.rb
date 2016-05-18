class SubscribeForCategory < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user
  belongs_to :item_category
  validates :shop_id, :user_id, :item_category_id, presence: true, uniqueness: true
  validates :subscribed_at, presence: true
end
