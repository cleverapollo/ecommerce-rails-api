module Rtb
  class Broker

    attr_reader :shop, :customer

    def initialize(shop)
      @shop = shop
      @customer = shop.customer
    end


    # TODO: использовать цену в локации покупателя
    # @return Boolean
    def notify(user, items)
      return false unless feature_available?
      return false unless items.respond_to? :each

      # Оставляем товары, с которыми можно работать
      items = items.select { |item| item.price && item.price >= @customer.currency.min_payment && item.widgetable? && item.is_available? && item.name.to_s.length < 1024 && item.image_url.to_s.length < 1024 && item.url.to_s.length < 1024 }.compact

      # Если товаров меньше 4, дополняем похожими
      if items.count > 0 && items.count < 4
        recommender_params = OpenStruct.new(
            shop: shop,
            user: user,
            limit: (8 - items.count),
            recommend_only_widgetable: true,
            recommender_type: 'similar',
            item: items.first,
            exclude: items.map(&:uniqid),
            locations: items.first.locations
        )
        recommended_ids = Recommender::Impl::Interesting.new(recommender_params).recommended_ids
        recommended_ids.each do |recommended_id|
          items << Item.find(recommended_id)
        end
      end

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
      true
    end


    # Очищает задачи по брошенным корзинам.
    # Если items != nil, удаляет только те задачи, которые про эти товары
    # Если items.nil?, то удаляет все брошенные корзины этого клиента
    # Возвращает nil
    def clear(user, items = nil)
      return false unless feature_available?
      if items.is_a? Array
        RtbJob.where(shop_id: shop.id, user_id: user.id, item_id: items.map(&:id)).where('active IS TRUE').update_all active: false
      else
        RtbJob.where(shop_id: shop.id, user_id: user.id).where('active IS TRUE').update_all active: false
      end
      nil
    end

    private

    def feature_available?
      shop.remarketing_enabled? && customer.balance > 0 && shop.active? && shop.connected? && !shop.restricted?
    end

  end
end
