##
# Событие, связанное с магазином.
#
class Event < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


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
      shop.events.create!(name: 'connected')
    end
  end
end
