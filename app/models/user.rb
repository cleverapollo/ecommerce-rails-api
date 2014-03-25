class User < ActiveRecord::Base
  has_and_belongs_to_many :shops
  has_many :shops_users, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :actions, dependent: :destroy

  after_initialize :assign_ab_testing_group

  def items_ids_bought_in_shop(shop)
    actions.where(shop_id: shop.id).where('purchase_count > 0').pluck(:item_id)
  end

  protected

    def assign_ab_testing_group
      self.ab_testing_group = (rand(2) + 1) if self.ab_testing_group.blank?
    end
end
