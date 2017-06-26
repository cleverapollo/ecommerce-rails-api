class ShopKPI

  # @return [Shop]
  attr_accessor :shop
  # @return [Date]
  attr_accessor :date
  # @return [ShopMetric]
  attr_accessor :shop_metric

  class << self

    # Так как статусы заказов синхронизируются часто намного позже, чем заказы создаются,
    # А также заказы с рассылок приходят значительно позже после их отправки,
    # нужно пересчитывать старые данные за 14 дней.
    def recalculate_all_for_last_period
      Shop.on_current_shard.connected.active.unrestricted.each do |shop|

        Time.use_zone(shop.customer.time_zone) do
          if shop.track_order_status?
            (0..13).each do |x|
              kpi = new(shop, Date.today - x.days).calculate_statistics
              kpi.calculate_products if x == 0
            end
          else
            new(shop).calculate_statistics.calculate_products
          end
        end

      end
    end

    def recalculate_for_today
      Shop.on_current_shard.connected.active.unrestricted.each do |shop|
        Time.use_zone(shop.customer.time_zone) do
          new(shop).calculate_statistics.calculate_products
        end
      end
    end

  end

  # @param [Shop] shop
  # @param [Date] date
  def initialize(shop, date = Date.current)
    @shop = shop
    @date = date
    @shop_metric = ShopMetric.find_or_create_by date: date, shop_id: shop.id
  end

  # Считает общую статистику
  def calculate_statistics

    Slavery.on_slave do
      @datetime_interval = date.beginning_of_day..date.end_of_day

      shop_metric.orders = orders_count
      shop_metric.real_orders = orders_count(true)
      shop_metric.revenue = revenue
      shop_metric.real_revenue = revenue(true)
      shop_metric.visitors = visitors_count
      shop_metric.products_viewed = products_viewed
      shop_metric.triggers_enabled_count = triggers_enabled_count

      shop_metric.orders_original_count = orders_count(false, 'original')
      shop_metric.orders_recommended_count = orders_count(false, 'recommended')
      shop_metric.orders_original_revenue = revenue(false, 'original')
      shop_metric.orders_recommended_revenue = revenue(false, 'recommended')

      # Пока не придумаем, как на тестах ходить в clickhouse, ставим костыль
      if Rails.env.production?
        shop_metric.product_views_total = Clickhouse.connection.query("SELECT COUNT(*) FROM rees46.interactions WHERE shop_id = #{shop.id} AND code = '1' AND created_at >= '#{@datetime_interval.first.to_formatted_s(:db)}' AND created_at <= '#{@datetime_interval.last.to_formatted_s(:db)}'").to_a.flatten.first.to_i
        shop_metric.product_views_recommended = Clickhouse.connection.query("SELECT COUNT(*) FROM rees46.interactions WHERE shop_id = #{shop.id} AND code = '1' AND recommender_code != '' AND created_at >= '#{@datetime_interval.first.to_formatted_s(:db)}' AND created_at <= '#{@datetime_interval.last.to_formatted_s(:db)}'").to_a.flatten.first.to_i
      else
        shop_metric.product_views_total = Interaction.where(shop_id: shop.id).where(created_at: @datetime_interval).views.count
        shop_metric.product_views_recommended = Interaction.where(shop_id: shop.id).where(created_at: @datetime_interval).views.from_recommender.count
      end

      # Ищем id товаров в заказах из товарных рекомендаций
      order_ids = Order.where(shop_id: shop.id, date: @datetime_interval).pluck(:id)
      shop_metric.orders_with_recommender_count = OrderItem.where(order_id: order_ids, recommended_by: Interaction::RECOMMENDER_CODES.keys).distinct(:order_id).count(:order_id)

      if shop_metric.triggers_enabled_count > 0

        # Используем здесь trigger_mailings_ids для активации индекса, т.к. индекса на только shop_id нет.
        trigger_mailings_ids = TriggerMailing.where(shop_id: shop.id).pluck(:id)
        if trigger_mailings_ids.count > 0
          relation = TriggerMail.where(trigger_mailing_id: trigger_mailings_ids).where(shop_id: shop.id).where(created_at: @datetime_interval).where('"date" >= ?', @datetime_interval.first.to_date)
          shop_metric.triggers_sent = relation.count
          shop_metric.triggers_clicked = relation.clicked.count
          mail_ids = relation.pluck(:id)
          if mail_ids.count > 0
            # All orders
            relation = Order.where(source_type: 'TriggerMail').where(shop_id: shop.id).where(source_id: mail_ids)
            shop_metric.triggers_orders = relation.count
            shop_metric.triggers_revenue = relation.where.not(value: nil).sum(:value)
            # Only paid orders
            shop_metric.triggers_orders_real = relation.successful.count
            shop_metric.triggers_revenue_real = relation.successful.where.not(value: nil).sum(:value)
          end
        end
      end

      # Web-push triggers
      web_push_trigger_ids = WebPushTrigger.where(shop_id: shop.id).pluck(:id)
      if web_push_trigger_ids.count > 0
        relation = WebPushTriggerMessage.where(web_push_trigger_id: web_push_trigger_ids, shop_id: shop.id).where(created_at: @datetime_interval).where('"date" >= ?', @datetime_interval.first.to_date)
        shop_metric.web_push_triggers_sent = relation.count
        shop_metric.web_push_triggers_clicked = relation.clicked.count
        if relation.count > 0
          relation = Order.where(source_type: 'WebPushTriggerMessage', shop_id: shop.id, source_id: relation.pluck(:id))
          # All orders
          shop_metric.web_push_triggers_orders = relation.count
          shop_metric.web_push_triggers_revenue = relation.where.not(value: nil).sum(:value)
          # Only paid orders
          shop_metric.web_push_triggers_orders_real = relation.successful.count
          shop_metric.web_push_triggers_revenue_real = relation.successful.where.not(value: nil).sum(:value)
        end
      end

      # Web-push digests
      relation = WebPushDigestMessage.where(shop_id: shop.id).where(created_at: @datetime_interval).where('"date" >= ?', @datetime_interval.first.to_date)
      shop_metric.web_push_digests_sent = relation.count
      shop_metric.web_push_digests_clicked = relation.clicked.count
      mail_ids = relation.pluck(:id)
      if mail_ids.length > 0
        relation = Order.where(source_type: 'WebPushDigestMessage').where(shop_id: shop.id).where(source_id: mail_ids)
        # All orders
        shop_metric.web_push_digests_orders = relation.count
        shop_metric.web_push_digests_revenue = relation.where.not(value: nil).sum(:value)
        # Only paid orders
        shop_metric.web_push_digests_orders_real = relation.successful.count
        shop_metric.web_push_digests_revenue_real = relation.successful.where.not(value: nil).sum(:value)
      end

      relation = DigestMail.where(shop_id: shop.id).where(created_at: @datetime_interval).where('"date" >= ?', @datetime_interval.first.to_date)
      shop_metric.digests_sent = relation.count
      shop_metric.digests_clicked = relation.clicked.count
      mail_ids = relation.pluck(:id)
      if mail_ids.length > 0
        relation = Order.where(source_type: 'DigestMail').where(shop_id: shop.id).where(source_id: mail_ids)
        # All orders
        shop_metric.digests_orders = relation.count
        shop_metric.digests_revenue = relation.where.not(value: nil).sum(:value)
        # Only paid orders
        shop_metric.digests_orders_real = relation.successful.count
        shop_metric.digests_revenue_real = relation.successful.where.not(value: nil).sum(:value)
      end

      # Remarketing
      client_carts = ClientCart.where(shop_id: shop.id, date: @datetime_interval.first.to_date..@datetime_interval.last.to_date)
      shop_metric.remarketing_carts = client_carts.length
      shop_metric.remarketing_impressions = Slavery.on_master { RtbImpression.where(shop_id: shop.id, date: @datetime_interval).count }
      shop_metric.remarketing_clicks = Slavery.on_master { RtbImpression.clicks.where(shop_id: shop.id, date: @datetime_interval).count }
      shop_metric.remarketing_orders = Order.where(shop_id: shop.id, source_type: 'RtbImpression', date: @datetime_interval).count
      shop_metric.remarketing_revenue = Order.where(shop_id: shop.id, source_type: 'RtbImpression', date: @datetime_interval).sum(:value)

      shop_metric.abandoned_products = client_carts.map {|x| x.items }.flatten.uniq.count
      shop_metric.abandoned_money = 0
      if shop_metric.abandoned_products > 0
        item_ids = client_carts.map {|x| x.items }.flatten.uniq
        shop_metric.abandoned_money = Item.where(id: item_ids).where.not(price: nil).sum(:price)
      end

      # Обновляем только за последний день, т.к. считается инкримент
      if date == Date.yesterday || date == Date.current

        # Subscriptions
        shop_metric.subscription_popup_showed = Client.where(shop_id: shop.id, subscription_popup_showed: true).count
        shop_metric.subscription_accepted = Client.where(shop_id: shop.id, subscription_popup_showed: true, accepted_subscription: true).count
        shop_metric.web_push_subscription_popup_showed = Client.where(shop_id: shop.id, web_push_subscription_popup_showed: true).count
        shop_metric.web_push_subscription_accepted = Client.where(shop_id: shop.id, web_push_enabled: true).count

      end
    end

    if date == Date.yesterday || date == Date.current
      # Recommenders request count
      shop_metric.recommendation_requests = Redis.current.get("recommender.request.#{shop.id}.#{date}")
    end

    shop_metric.save! if shop_metric.changed?

    self
  end

  # Считает товары
  def calculate_products

    Slavery.on_slave do
      products = Retailer::Products::OverviewStatistic.new shop
      shop_metric.products_statistics = {
          total: products.total,
          recommendable: products.recommendable,
          widgetable: products.widgetable,
          ignored: products.ignored,
          industrial: products.industrial
      }
      shop_metric.top_products = OrderItem.where(shop_id: shop.id, order_id: Order.where(shop_id: shop.id).where('date >= ?', 1.month.ago)).group(:item_id).count.to_a.sort_by { |x| x[1] }.reverse[0..2].map { |x| item = Item.find(x[0]); {id: item.id, name: item.name.present? ? item.name : item.uniqid, url: item.url, amount: x[1]} }
    end

    shop_metric.save! if shop_metric.changed?
  end

  # Count of shop orders
  # @param only_real [Boolean] Count only real orders (with synced statuses)
  # @param filter [original|recommended] Filter only original or recommended orders
  # @return Integer
  def orders_count(only_real = false, filter = nil)
    result = Order.where(shop_id: @shop.id).where(date: @datetime_interval)
    if only_real
      result = result.successful
    end
    case filter
      when 'original'
        result = result.where(recommended: false)
      when 'recommended'
        result = result.where(recommended: true)
    end
    result.count
  end

  # Calculate shop's revenue
  # @param only_real [Boolean] Use only real orders (with synced statuses)
  # @param filter [original|recommended] Filter only original or recommended orders
  # @return Numeric
  def revenue(only_real = false, filter = nil)
    result = Order.where(shop_id: @shop.id).where(date: @datetime_interval)
    if only_real
      result = result.where(status: 1)
    end
    case filter
      when 'original'
        result.sum(:common_value)
      when 'recommended'
        result.sum(:recommended_value)
      else
        result.sum(:value)
    end
  end

  def visitors_count
    Visit.where(shop_id: @shop.id, date: @datetime_interval.first.to_date).count
  end

  def products_viewed
    Action.where(shop_id: @shop.id).where(timestamp: @datetime_interval).count
  end

  def triggers_enabled_count
    TriggerMailing.enabled.where(shop_id: @shop.id).count
  end



end
