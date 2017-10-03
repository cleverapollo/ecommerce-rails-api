module Rtb
  class Broker

    attr_reader :shop, :customer

    class << self

      def cleanup_expired
        # Считаем, что через два дня после брошенной корзины покупатель уже где-то купил этот товар
        RtbJob.where('date < ?', 5.days.ago.beginning_of_day).where('counter = 0').delete_all
      end

    end


    def initialize(shop)
      @shop = shop
      @customer = shop.customer
    end


    # TODO: использовать цену в локации покупателя
    # @param [Session] session
    # @param [User] user
    # @return Boolean
    def notify(session, user, item_ids)
      return false unless feature_available?
      return false unless item_ids.respond_to? :each

      # @type [Array] items
      items = Item.find(item_ids)
      return false unless items.any?

      min_remarketing_product_price = Currency.find_by(code: @shop.currency_code).remarketing_min_price

      # Оставляем товары, с которыми можно работать
      items = items.select { |item| item.price && item.price >= min_remarketing_product_price && item.widgetable? && item.is_available? && item.name.to_s.length < 1024 && item.image_url.to_s.length < 1024 && item.url.to_s.length < 1024 }.compact

      # Если товаров меньше 4, дополняем похожими
      if items.count > 0 && items.count < 4
        recommender_params = OpenStruct.new(
            shop: shop,
            user: user,
            session: session,
            limit: (6 - items.count),
            recommend_only_widgetable: true,
            recommender_type: 'similar',
            item: items.first,
            exclude: items.map(&:uniqid),
            locations: items.first.locations,
            request: OpenStruct.new(referer: 'Broker', useragent: 'Broker')
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
        job.update counter: 0, date: Date.current, currency: item[:currency], url: item[:url], active: true, products: items
      else
        job = RtbJob.create! shop_id: shop.id, user_id: user.id, source_user_id: user.id, date: Date.current, counter: 0, currency: item[:currency], url: item[:url], logo: shop.fetch_logo_url, products: items
      end

      # Сохраняем в редис
      begin
        Redis.rtb.setex("RMRK:#{user.id}:#{shop.id}", 432000, {id: job.id, counter: 0, shop_id: shop.id, user_id: user.id, currency: job.currency, url: job.url, logo: job.logo, products: job.products}.to_json )
      rescue => e
        Rollbar.error e
      end

      true
    end


    # Очищает задачи по брошенным корзинам.
    # param user [User]
    # @return nil
    def clear(user)
      return false unless feature_available?
      RtbJob.where(shop_id: shop.id, user_id: user.id).where('active IS TRUE').update_all active: false
      RtbJob.where(shop_id: shop.id, source_user_id: user.id).where('active IS TRUE').update_all active: false
      begin
        Redis.rtb.del("RMRK:#{user.id}:#{shop.id}")
      rescue => e
        Rollbar.error e
      end
      nil
    end

    private

    def feature_available?
      shop.remarketing_enabled? && customer.balance > 0 && shop.active? && shop.connected? && !shop.restricted?
    end

  end
end
