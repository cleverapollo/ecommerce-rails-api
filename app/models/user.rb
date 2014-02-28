class User < ActiveRecord::Base
  has_many :sessions
  has_many :actions

  after_initialize :assign_ab_testing_group

  def items_ids_bought_in_shop(shop)
    actions.where(shop_id: shop.id).where('purchase_count > 0').pluck(:item_id)
  end

  protected

    def assign_ab_testing_group
      self.ab_testing_group = (rand(2) + 1) if self.ab_testing_group.blank?
    end
end
