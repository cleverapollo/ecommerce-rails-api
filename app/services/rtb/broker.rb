module Rtb
  class Broker

    attr_reader :shop, :customer

    def initialize(shop)
      @shop = shop
      @customer = shop.customer
    end


    # TODO: использовать цену в локации покупателя
    # @return nil, false, [массив урлов для попандеров]
    def notify(user, items)
      return false unless feature_available?
      return false unless items.respond_to? :each

      # Оставляем товары, с которыми можно работать
      items = items.select { |item| item.price && item.price >= @customer.currency.min_payment && item.widgetable? && item.is_available? && item.name.to_s.length < 1024 && item.image_url.to_s.length < 1024 && item.url.to_s.length < 1024 }.compact

      # Переводим в массив с нужными данными
      items = items.map { |item| {id: item.id, uniqid: item.uniqid, price: item.price.round, oldprice:  item.oldprice.present? ? item.oldprice.round : nil, image: item.resized_image_by_dimension('200x200'), url: item.url, name: item.name, currency: shop.currency } }

      # Ничего не осталось
      return false unless items.any?

      # Legacy - оставляем один самый дорогой товар для временного сохранения старой функциональности по баннерам
      item =  if items.count > 1
        items.sort { |a,b| a[:price] <=> b[:price] }.first
      else
        items.first
      end

      if job = RtbJob.active_for_user(user).where(shop_id: shop.id).first
        job.update counter: 0, date: Date.current, price: item[:price], image: item[:image], name: item[:name], currency: item[:currency], url: item[:url], products: items
      else
        begin
          job = RtbJob.create! shop_id: shop.id, user_id: user.id, item_id: item[:id], date: Date.current, counter: 0, price: item[:price], image: item[:image], name: item[:name], currency: item[:currency], url: item[:url], logo: shop.fetch_logo_url, products: items
        rescue  ActiveRecord::RecordNotUnique
          job = RtbJob.active_for_user(user).where(shop_id: shop.id).first
        end
      end

      # items.each do |item|
      #   # Комиссия с продажи такого товара – 46 рублей
      #   if item.price && item.price >= @customer.currency.min_payment && item.widgetable? && item.is_available? && item.name.to_s.length < 255 && item.image_url.to_s.length < 255 && item.url.to_s.length < 255
      #     if rtb_item = RtbJob.find_by(shop_id: shop.id, user_id: user.id, item_id: item.id)
      #       rtb_item.update counter: 0, date: Date.current, price: item.price, image: item.image_url, name: item.name, currency: shop.currency, url: item.url
      #     else
      #       begin
      #         rtb_item = RtbJob.create! shop_id: shop.id, user_id: user.id, item_id: item.id, date: Date.current, counter: 0, price: item.price, image: item.image_url, name: item.name, currency: shop.currency, url: item.url, logo: shop.fetch_logo_url
      #       rescue ActiveRecord::RecordNotUnique
      #         # Concurrency
      #         rtb_item = RtbJob.find_by(shop_id: shop.id, user_id: user.id, item_id: item.id)
      #       end
      #     end
      #     if popunder_item.nil? || popunder_item.price < item.price
      #       popunder_item = item
      #       popunder_job = rtb_item
      #     end
      #   end
      # end
      #
      # if popunder_item && popunder_enabled?
      #   url = "http://zloe.net/?shop_id=#{shop.uniqid}&item_id=#{popunder_item.uniqid}&source_id=#{popunder_job.id}"
      #   ["//my.rtmark.net/img.gif?partner=990&ttl=86400&f=nosync&rurl=#{CGI::escape(url)}"]
      # else
      #   return nil
      # end

    end


    # Очищает задачи по брошенным корзинам.
    # Если items != nil, удаляет только те задачи, которые про эти товары
    # Если items.nil?, то удаляет все брошенные корзины этого клиента
    # Возвращает
    def clear(user, items = nil)
      return false unless feature_available?
      if items.is_a? Array
        RtbJob.where(shop_id: shop.id, user_id: user.id, item_id: items.map(&:id)).where('active IS TRUE').update_all active: false
      else
        RtbJob.where(shop_id: shop.id, user_id: user.id).where('active IS TRUE').update_all active: false
      end
      popunder_enabled? ? ['//my.rtmark.net/img.gif?partner=990&f=off'] : nil
    end

    private

    def feature_available?
      shop.remarketing_enabled? && customer.balance > 0 && shop.active? && shop.connected? && !shop.restricted?
    end

    def popunder_enabled?
      shop.popunder_enabled?
    end


  end
end
