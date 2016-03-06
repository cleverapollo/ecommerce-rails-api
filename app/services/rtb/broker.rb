module Rtb
  class Broker

    attr_reader :shop, :customer

    def initialize(shop)
      @shop = shop
      @customer = shop.customer
    end


    # TODO: использовать цену в локации покупателя
    def notify(user, items)
      return false unless feature_available?
      return false unless items.is_a? Array
      items.each do |item|
        # Комиссия с продажи такого товара – 92 рубля, вроде годная цена
        if item.price >= 2000 && item.widgetable? && item.is_available? && item.name.length < 255 && item.image_url.length < 255 && item.url.length < 255
          if rtb_item = RtbJob.find_by(shop_id: shop.id, user_id: user.id, item_id: item.id)
            rtb_item.update counter: 0, date: Date.current, price: item.price, image: item.image_url, name: item.name, currency: shop.currency, url: item.url
          else
            RtbJob.create! shop_id: shop.id, user_id: user.id, item_id: item.id, date: Date.current, counter: 0, price: item.price, image: item.image_url, name: item.name, currency: shop.currency, url: item.url
          end
        end
      end
    end


    # Очищает задачи по брошенным корзинам.
    # Если items != nil, удаляет только те задачи, которые про эти товары
    # Если items.nil?, то удаляет все брошенные корзины этого клиента
    def clear(user, items = nil)
      return false unless feature_available?
      if items.is_a? Array
        RtbJob.where(shop_id: shop.id, user_id: user.id, item_id: items.map(&:id)).delete_all
      else
        RtbJob.where(shop_id: shop.id, user_id: user.id).delete_all
      end
      nil
    end

    private

    def feature_available?
      shop.remarketing_enabled? && customer.balance > 0
    end


  end
end