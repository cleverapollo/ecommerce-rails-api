class Visit < ActiveRecord::Base

  validates :shop_id, :user_id, :date, presence: true
  validates :shop_id, uniqueness: { scope: [:user_id, :date] }

  belongs_to :shop
  belongs_to :user

  class << self

    # Перелинковка данных при склеивании пользователей
    # @param options [Hash]
    def relink_user(options = {})
      master = options.fetch(:to)
      slave = options.fetch(:from)
      slave.visits.each do |slave_row|
        if master_row = Visit.find_by(user_id: master.id, shop_id: slave_row.shop_id, date: slave_row.date)
          master_row.update pages: (master_row.pages + slave_row.pages)
          slave_row.delete
        else
          slave_row.update_columns(user_id: master.id)
        end
      end
    end

  end

end
