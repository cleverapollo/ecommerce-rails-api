class ShopEventsReporter
  AUTH = {
    username: '9f6d930309176dac405ee6af987b0cf6',
    password: '2b92ad2081bab4b690db252153b53978'
  }

  URL = Rails.env.production? ? 'https://rees46.com/events' : 'http://localhost:3000/events'

  class << self
    def event_tracked(shop)
      send('event_tracked', shop.id)
    end

    def recommendation_given(shop)
      send('recommendation_given', shop.id)
    end

    def connected(shop)
      send('connected', shop.id)
    end

    def send(name, shop_id)
      return if Rails.env.test?

      body = {
        event: {
          name: name,
          shop_id: shop_id
        }
      }

      HTTParty.post(URL, body: body, basic_auth: AUTH)
    end
  end
end
