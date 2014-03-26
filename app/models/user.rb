class User < ActiveRecord::Base
  has_and_belongs_to_many :shops
  has_many :shops_users, dependent: :delete_all
  has_many :sessions, dependent: :destroy
  has_many :actions, dependent: :destroy

  def items_ids_bought_in_shop(shop)
    actions.where(shop_id: shop.id).where('purchase_count > 0').pluck(:item_id)
  end

  def ensure_linked_to_shop(shop_id)
    begin
      if s_u = shops_users.find_by(shop_id: shop_id)
        s_u
      else
        shops_users.create(shop_id: shop_id)
      end
    rescue ActiveRecord::RecordNotUnique => e
      shops_users.find_by(shop_id: shop_id)
    end
  end

  def ab_testing_group_in(shop)
    ensure_linked_to_shop(shop.id).ab_testing_group
  end
end
