class User < ActiveRecord::Base
  has_and_belongs_to_many :shops
  has_many :shops_users, dependent: :delete_all
  has_many :sessions, dependent: :destroy
  has_many :actions, dependent: :destroy

  def items_ids_bought_in_shop(shop)
    actions.where(shop_id: shop.id).where('purchase_count > 0').pluck(:item_id)
  end

  def ab_testing_group_in(shop)
    shops_users.find_by(shop_id: shop.id).ab_testing_group
  end
end
