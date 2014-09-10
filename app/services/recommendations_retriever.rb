class RecommendationsRetriever
  attr_accessor :shop
  attr_accessor :limit
  attr_accessor :user
  attr_accessor :mahout_service

  attr_accessor :recommendations

  def initialize(shop, limit)
    @shop, @limit = shop, limit
    @mahout_service = MahoutService.new

    begin
      Timeout::timeout(2) {
        @mahout_service.open
      }
    rescue Timeout::Error => e
      retry
    end
  end

  def popular(count)
    unless @popular.present?
      @popular = shop.actions.where('purchase_count > 0').where(is_available: true).select(:item_id).group(:item_id).order('SUM(purchase_count) desc').limit(20).map(&:item_id)

      @popular = Item.where(id: @popular).available.select(&:widgetable?).map do |item|
        item.url = UrlHelper.add_param(item.url, utm_source: 'rees46')
        item.url = UrlHelper.add_param(item.url, utm_meta: 'email_digest')
        item.url = UrlHelper.add_param(item.url, utm_campaign: 'popular')
        item.url = UrlHelper.add_param(item.url, recommended_by: 'popular')
        item
      end
    end

    @popular.slice(0, count)
  end


  def for(user)
    flush_caches
    @user = user
    result = []

    result = result + viewed_but_not_bought(3) + interesting(3)

    result = result + popular(self.limit - result.count)

    result
  end

  def flush_caches
    @bought_ids = nil
    @bought_categories = nil
    @also_bought_with = nil
  end

  def business_rules
    []
  end

  def bought_relation
    user.actions.where(rating: 5, shop_id: shop)
  end

  def bought_ids
    @bought_ids ||= bought_relation.to_a.map(&:item_id)
  end

  def bought_categories
    @bought_categories ||= bought_relation.to_a.map(&:category_uniqid).uniq.compact
  end

  def viewed_but_not_bought(limit)
    return [] unless user.persisted?

    ids = user.actions.where('rating <= 3.2').where('item_id NOT IN (?)', bought_ids).where('category_uniqid NOT IN (?)', bought_categories).where('timestamp >= ?', 1.month.ago.to_i).order('view_count desc, timestamp desc').limit(limit).pluck(:item_id)

    res = Item.where(id: ids).available.select(&:widgetable?).map do |item|
      item.url = UrlHelper.add_param(item.url, utm_source: 'rees46')
      item.url = UrlHelper.add_param(item.url, utm_meta: 'email_digest')
      item.url = UrlHelper.add_param(item.url, utm_campaign: 'viewed_but_not_bought')
      item.url = UrlHelper.add_param(item.url, recommended_by: 'interesting')
      item
    end
    res
  end

  def also_bought_with(ids)
    @also_bought_with ||= OrderItem.select(:item_id)
                         .where('order_id IN (SELECT DISTINCT order_id FROM order_items WHERE item_id IN (?))', ids)
                         .group('item_id')
                         .order('count(item_id) desc')
                         .limit(20).pluck(:item_id)
  end

  def items_in_shop
    @items_in_shop ||= shop.items.available.pluck(:id)
  end

  def interesting(limit)
    mahout_ids = []
    begin
      Timeout::timeout(2) {
        mahout_ids = mahout_service.user_based(user.id, shop.id, nil,
          include: items_in_shop,
          exclude: Recommender::Base.exclude_in_recommendations(user.id, shop.id),
          limit: limit
        )
      }
    rescue Timeout::Error => e
      retry
    end

    res = Item.where(id: mahout_ids).select(&:widgetable?).map do |item|
      item.url = UrlHelper.add_param(item.url, utm_source: 'rees46')
      item.url = UrlHelper.add_param(item.url, utm_meta: 'email_digest')
      item.url = UrlHelper.add_param(item.url, utm_campaign: 'interesting')
      item.url = UrlHelper.add_param(item.url, recommended_by: 'interesting')
      item
    end
    res
  end

  def init_recommendations
    @recommendations = [
      [nil, nil, nil],
      [nil, nil, nil],
      [nil, nil, nil]
    ]
  end
end
