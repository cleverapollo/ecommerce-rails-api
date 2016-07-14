class SubscribeForCategory < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user
  belongs_to :item_category
  validates :shop_id, :user_id, :item_category_id, presence: true
  validates :subscribed_at, presence: true

  class << self

    # Перелинковка данных при склеивании пользователей
    # @param options [Hash]
    def relink_user(options = {})
      master = options.fetch(:to)
      slave = options.fetch(:from)
      slave.subscribe_for_categories.each do |slave_row|
        if master_row = SubscribeForCategory.find_by(user_id: master.id, item_category_id: slave_row.item_category_id)
          slave_row.delete
        else
          slave_row.update_columns(user_id: master.id)
        end
      end
    end

  end

end
