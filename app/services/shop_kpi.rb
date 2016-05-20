class ShopKPI

  class << self

    # Неактуален, так как работает только со вчерашним днем, а это неполные данные для рассылок
    # и синхронизации статусов заказов
    # def process_all
    #   Shop.on_current_shard.connected.active.unrestricted.each do |shop|
    #     new(shop).calculate_and_write_statistics_at(Date.yesterday)
    #   end
    # end

    # Так как статусы заказов синхроинизируются часто намного позже, чем заказы создаются,
    # А также заказы с рассылок приходят значительно позже после их отправки,
    # нужно пересчитывать старые данные за 14 дней.
    def recalculate_all_for_last_period
      Shop.on_current_shard.connected.active.unrestricted.each do |shop|
        (1..14).each do |x|
          new(shop).calculate_and_write_statistics_at(Date.today - x.days)
        end
      end
    end

  end

  def initialize(shop)
    @shop = shop
  end

  def calculate_and_write_statistics_at(date = Date.current)

    @datetime_interval = date.beginning_of_day..date.end_of_day

    @shop_metric = ShopMetric.find_or_initialize_by date: date, shop_id: @shop.id
    @shop_metric.orders = orders_count
    @shop_metric.real_orders = orders_count(true)
    @shop_metric.revenue = revenue
    @shop_metric.real_revenue = revenue(true)
    @shop_metric.visitors = visitors_count
    @shop_metric.products_viewed = products_viewed
    @shop_metric.triggers_enabled_count = triggers_enabled_count

    @shop_metric.orders_original_count = orders_count(false, 'original')
    @shop_metric.orders_recommended_count = orders_count(false, 'recommended')
    @shop_metric.orders_original_revenue = revenue(false, 'original')
    @shop_metric.orders_recommended_revenue = revenue(false, 'recommended')

    @shop_metric.product_views_total = Interaction.where(shop_id: @shop.id).where(created_at: @datetime_interval).views.count
    @shop_metric.product_views_recommended = Interaction.where(shop_id: @shop.id).where(created_at: @datetime_interval).views.from_recommender.count

    if @shop_metric.triggers_enabled_count > 0

      # Используем здесь trigger_mailings_ids для активации индекса, т.к. индекса на только shop_id нет.
      trigger_mailings_ids = TriggerMailing.where(shop_id: @shop.id).pluck(:id)
      if trigger_mailings_ids.count > 0
        relation = TriggerMail.where(trigger_mailing_id: trigger_mailings_ids).where(shop_id: @shop.id).where(created_at: @datetime_interval)
        @shop_metric.triggers_sent = relation.count
        @shop_metric.triggers_clicked = relation.clicked.count
        mail_ids = relation.pluck(:id)
        if mail_ids.count > 0
          # All orders
          relation = Order.where(source_type: 'TriggerMail').where(shop_id: @shop.id).where(source_id: mail_ids)
          @shop_metric.triggers_orders = relation.count
          @shop_metric.triggers_revenue = relation.where.not(value: nil).sum(:value)
          # Only paid orders
          @shop_metric.triggers_orders_real = relation.successful.count
          @shop_metric.triggers_revenue_real = relation.successful.where.not(value: nil).sum(:value)
        end
      end
    end

    relation = DigestMail.where(shop_id: @shop.id).where(created_at: @datetime_interval)
    @shop_metric.digests_sent = relation.count
    @shop_metric.digests_clicked = relation.clicked.count
    mail_ids = relation.pluck(:id)
    if mail_ids.length > 0
      relation = Order.where(source_type: 'DigestMail').where(shop_id: @shop.id).where(source_id: mail_ids)
      # All orders
      @shop_metric.digests_orders = relation.count
      @shop_metric.digests_revenue = relation.where.not(value: nil).sum(:value)
      # Only paid orders
      @shop_metric.digests_orders_real = relation.successful.count
      @shop_metric.digests_revenue_real = relation.successful.where.not(value: nil).sum(:value)
    end

    actions = Action.where(shop_id: @shop.id).where(timestamp: @datetime_interval).pluck(:item_id, :rating).delete_if { |x| x[1] != 4.2 }
    @shop_metric.abandoned_products = actions.count
    @shop_metric.abandoned_money = 0
    if @shop_metric.abandoned_products > 0
      item_ids = actions.map { |x| x[0] }.uniq
      prices = Item.where(id: item_ids.uniq).where.not(price: nil).pluck(:id, :price)
      item_ids.each do |item_id|
        if price = prices.select{ |x| x[0] == item_id }.first
          @shop_metric.abandoned_money += price[1]
        end
      end
    end

    # Subscriptions
    @shop_metric.subscription_popup_showed = Client.where(shop_id: @shop.id).where('subscription_popup_showed IS TRUE').count
    @shop_metric.subscription_accepted = Client.where(shop_id: @shop.id).where('subscription_popup_showed IS TRUE').where('accepted_subscription IS TRUE').count

    @shop_metric.save!

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
    Action.where(shop_id: @shop.id).where(timestamp: @datetime_interval).count('DISTINCT actions.user_id')
  end

  def products_viewed
    Action.where(shop_id: @shop.id).where(timestamp: @datetime_interval).count
  end

  def triggers_enabled_count
    TriggerMailing.enabled.where(shop_id: @shop.id).count
  end



end