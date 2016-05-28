class SubscribeForProductPrice < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user
  belongs_to :item
  validates :shop_id, :user_id, :item_id, presence: true, uniqueness: true
  validates :subscribed_at, presence: true
end
