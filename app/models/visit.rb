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
      relink_user_remnants(master, slave.id)
    end

    # @param [User] master
    # @param [Integer] slave_id
    def relink_user_remnants(master, slave_id)
      where(user_id: slave_id).each do |slave_row|
        master_row = Visit.find_by(user_id: master.id, shop_id: slave_row.shop_id, date: slave_row.date)
        if master_row.present?
          master_row.update pages: (master_row.pages + slave_row.pages)
          slave_row.delete
        else
          begin
            slave_row.update_columns(user_id: master.id)
          rescue ActiveRecord::RecordNotUnique
            master_row = Visit.find_by(user_id: master.id, shop_id: slave_row.shop_id, date: slave_row.date)
            master_row.update pages: (master_row.pages + slave_row.pages)
            slave_row.delete
          end
        end
      end
    end

  end

end
