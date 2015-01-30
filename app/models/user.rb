class User < ActiveRecord::Base
  include Redis::Objects

  has_many :clients
  has_many :sessions
  has_many :actions
  has_many :orders

  lock :merging, expiration: 60, timeout: 1

  # TODO: refactor
  def to_s
    "User ##{id}"
  end

  # TODO: refactor
  def items_ids_bought_in_shop(shop)
    actions.where(shop_id: shop.id).where('purchase_count > 0').pluck(:item_id)
  end

  # TODO: refactor
  def ensure_linked_to_shop(shop_id)
    begin
      if s_u = clients.find_by(shop_id: shop_id)
        s_u
      else
        clients.create(shop_id: shop_id)
      end
    rescue ActiveRecord::RecordNotUnique => e
      clients.find_by(shop_id: shop_id)
    end
  end

  # TODO: refactor
  def ab_testing_group_in(shop)
    ensure_linked_to_shop(shop.id).ab_testing_group
  end
end
