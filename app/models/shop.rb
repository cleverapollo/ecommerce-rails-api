class Shop < ActiveRecord::Base
  has_many :user_shop_relations
  has_many :items

  def available_item_ids
    items.available.pluck(:id)
  end
end
