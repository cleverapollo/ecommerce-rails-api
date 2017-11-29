class EventsConnected < ActiveRecord::Base
  self.table_name = 'events_connected'
  self.is_view = true
  establish_connection "#{Rails.env}_clickhouse".to_sym
  
  belongs_to :shop
  
  class << self
    
    # Получает последние даты событий в магазине
    # @return [Hash] {"view" => Date, "cart" => Date, ... }
    def for_shop(shop_id)
      where(shop_id: shop_id).select(:event).group(:event).maximum(:created_at)
    end
    
  end
  
end
