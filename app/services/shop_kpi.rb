class ShopKPI

  class << self

    def process_all
      Shop.on_current_shard.connected.active.unrestricted.each do |shop|
        new(shop).calculate_and_write_statistics_at(Date.yesterday)
      end
    end

    # Так как статусы заказов синхроинизируются часто намного позже, чем заказы создаются, нужно пересчитывать старые данные
    def recalculate_all_for_last_week
      Shop.on_current_shard.connected.active.unrestricted.with_tracking_orders_status.each do |shop|
        (1..7).each do |x|
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
    @shop_metric.real_orders = orders_count(true) if @shop.track_order_status?
    @shop_metric.revenue = revenue
    @shop_metric.real_revenue = revenue(true) if @shop.track_order_status?
    @shop_metric.orders_quality = orders_quality @shop_metric.orders, @shop_metric.real_orders
    @shop_metric.visitors = visitors_count
    @shop_metric.products_viewed = products_viewed
    @shop_metric.conversion = conversion( (@shop.track_order_status? ? @shop_metric.real_orders : @shop_metric.orders) , @shop_metric.visitors)
    @shop_metric.arpu = arpu( (@shop.track_order_status? ? @shop_metric.real_revenue : @shop_metric.revenue) , @shop_metric.visitors)
    @shop_metric.arppu = @shop.track_order_status? ? arppu(@shop_metric.real_revenue, @shop_metric.real_orders) : arppu(@shop_metric.revenue, @shop_metric.orders)
    @shop_metric.triggers_enabled_count = triggers_enabled_count

    if @shop_metric.triggers_enabled_count > 0
      trigger_mailings_ids = TriggerMailing.enabled.where(shop_id: @shop.id).pluck(:id)
      if trigger_mailings_ids.count > 0
        relation = TriggerMail.where(trigger_mailing_id: trigger_mailings_ids).where(created_at: @datetime_interval)
        triggers_sent = relation.count
        if triggers_sent > 0
          @shop_metric.triggers_ctr = relation.clicked.count.to_f / triggers_sent.to_f
          relation = Order.where(id: OrderItem.select(:order_id).where(shop_id: @shop.id).where(recommended_by: 'trigger_mail') ).where(date: @datetime_interval)
          relation = relation.successful if @shop.track_order_status?
          @shop_metric.triggers_orders = relation.count
          @shop_metric.triggers_revenue = relation.sum(:value)
        end
      end
    end


    relation = DigestMail.where(shop_id: @shop.id).where(created_at: @datetime_interval)
    digests_sent = relation.count
    if digests_sent > 0
      @shop_metric.digests_ctr = relation.clicked.count.to_f / digests_sent.to_f
      relation = Order.where(id: OrderItem.select(:order_id).where(shop_id: @shop.id).where(recommended_by: 'digest_mail') ).where(date: @datetime_interval)
      relation = relation.successful if @shop.track_order_status?
      @shop_metric.digests_orders = relation.count
      @shop_metric.digests_revenue = relation.where.not(value: nil).sum(:value)
    end

    actions = Action.where(shop_id: @shop.id).where(timestamp: @datetime_interval).pluck(:item_id, :rating).delete_if { |x| x[1] != 4.2 }
    @shop_metric.abandoned_products = actions.count
    if @shop_metric.abandoned_products > 0
      item_ids = actions.map { |x| x[0] }.uniq
      prices = Item.where(id: item_ids.uniq).where.not(price: nil).pluck(:id, :price)
      item_ids.each do |item_id|
        if price = prices.select{ |x| x[0] == item_id }.first
          @shop_metric.abandoned_money += price[1]
        end
      end
    end

    @shop_metric.save!

  end

  def orders_count(only_real = false)
    result = Order.where(shop_id: @shop.id).where(date: @datetime_interval)
    if only_real
      result = result.successful
    end
    result.count
  end

  def revenue(only_real = false)
    result = Order.where(shop_id: @shop.id).where(date: @datetime_interval)
    if only_real
      result = result.where(status: 1)
    end
    result.sum(:value)
  end

  def orders_quality(all_orders, real_orders)
    all_orders > 0 ? (real_orders.to_f / all_orders.to_f) : 0.0
  end

  def visitors_count
    Action.where(shop_id: @shop.id).where(timestamp: @datetime_interval).count('DISTINCT actions.user_id')
  end

  def products_viewed
    Action.where(shop_id: @shop.id).where(timestamp: @datetime_interval).count
  end

  def conversion(orders, visitors)
    visitors > 0 ? orders.to_f / visitors.to_f : 0
  end

  def arpu(revenue, visitors)
    visitors > 0 ? revenue.to_f / visitors.to_f : 0
  end

  def arppu(revenue, orders)
    orders > 0 ? revenue.to_f / orders.to_f : 0
  end

  def triggers_enabled_count
    TriggerMailing.enabled.where(shop_id: @shop.id).count
  end



end