class SubscribeForProductAvailable < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user
  belongs_to :item
  validates :shop_id, :user_id, :item_id, presence: true
  validates :subscribed_at, presence: true



  class << self

    # Перелинковка данных при склеивании пользователей
    # @param options [Hash]
    def relink_user(options = {})
      master = options.fetch(:to)
      slave = options.fetch(:from)
      slave.subscribe_for_product_availables.each do |slave_row|
        if master_row = SubscribeForProductAvailable.find_by(user_id: master.id, item_id: slave_row.item_id)
          slave_row.delete
        else
          slave_row.update_columns(user_id: master.id)
        end
      end
    end

  end
  
  
  
end
