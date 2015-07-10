##
# Событие, связанное с магазином.
#
class Event < ActiveRecord::Base

  belongs_to :shop

  validates :shop_id, presence: true
  validates :name, presence: true

  class << self
    def event_tracked(shop)
      shop.events.create!(name: 'event_tracked')
    end

    def recommendation_given(shop)
      shop.events.create!(name: 'recommendation_given')
    end

    def connected(shop)
      last_connection = Event.where(name: 'connected', shop_id: shop.id).last
      if last_connection.blank? || (last_connection.present? && last_connection.created_at.to_date != Date.current)
        shop.events.create!(name: 'connected')
      end
    end
  end
end
