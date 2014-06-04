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
      @popular = shop.actions.where('purchase_count > 0').where(is_available: true).select(:item_id).group(:item_id).order('SUM(purchase_count) desc').limit(15).map(&:item_id)
    end

    @popular.slice(0, count)
  end


  def for(user)
    flush_caches

    @user = user

    puts 'viewed_but_not_bought'
    v_b_n_b = viewed_but_not_bought
    puts v_b_n_b.join(', ')
    puts '====================='

    puts 'also_bought_with'
    puts also_bought_with(bought_ids).join(', ')
    puts '====================='

    puts 'popular'
    puts popular.join(', ')
    puts '====================='

    puts 'interesting'
    puts interesting.join(', ')
    puts '====================='
  end

  def flush_caches
    @bought_ids = nil
    @bought_categories = nil
    @also_bought_with = nil
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

  def viewed_but_not_bought
    user.actions.where('rating <= 3.2').where('item_id NOT IN (?)', bought_ids).where('category_uniqid NOT IN (?)', bought_categories).where('timestamp >= ?', 1.week.ago.to_i).pluck(:item_id)
  end

  def popular
    @popular ||= shop.actions.select(:item_id).where('timestamp > ?', 1.month.ago.to_i).where('purchase_count > 0').where(is_available: true).group(:item_id).order('SUM(purchase_count) DESC').limit(20).map(&:item_id)
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

  def interesting
    mahout_ids = []
    begin
      Timeout::timeout(2) {
        mahout_ids = mahout_service.user_based(user.id, shop.id, nil,
          include: items_in_shop,
          exclude: Recommender::Base.exclude_in_recommendations(user.id, shop.id),
          limit: 20
        )
      }
    rescue Timeout::Error => e
      retry
    end
    mahout_ids
  end

  def init_recommendations
    @recommendations = [
      [nil, nil, nil],
      [nil, nil, nil],
      [nil, nil, nil]
    ]
  end
end
