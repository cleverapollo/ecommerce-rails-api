class DigestMailingRecommendationsCalculator
  class MahoutOpenError < StandardError; end

  attr_reader :mahout_service

  class << self
    def create(shop, limit)
      calculator = new(shop, limit)
      calculator.mahout_service.open
      yield calculator
      calculator.mahout_service.close
    end
  end

  def initialize(shop, limit)
    @shop  = shop
    @limit = limit
    @items_cache = {}
    @mahout_service = MahoutService.new
    @items_in_shop = @shop.items.available.pluck(:id)
  end

  def recommendations_for(user)
    @user = user
    if mahout_tunnel_open?
      interesting_ids = interesting_recommendations
      recommendation_ids = if interesting_ids.size < @limit
        params = OpenStruct.new(
          shop: @shop,
          user: @user,
          limit: @limit - interesting_ids.size,
          recommender_type: 'popular',
          excluded_item_ids: interesting_ids
        )
        popular_ids = Recommender::Impl::Popular.new(params).recommended_ids
        interesting_ids + popular_ids
      else
        interesting_ids
      end

      items(recommendation_ids)
    else
      raise MahoutOpenError.new('Махаут тунель не открылся')
    end
  end

  private

  def items(ids)
    result = []
    from_base = []
    ids.each do |id|
      if @items_cache[id].blank?
        from_base << id
      else
        result << @items_cache[id]
      end
    end
    result += Item.where(id: from_base).each { |item| @items_cache[item.id] = item } if from_base.any?
    result
  end

  def mahout_tunnel_open?
    mahout_service.tunnel && mahout_service.tunnel.active?
  end

  def interesting_recommendations
    return [] if @user.nil?
    Timeout::timeout(2) {
      mahout_service.user_based(
        @user.id,
        @shop.id,
        nil,
        include: @items_in_shop,
        exclude: @shop.item_ids_bought_or_carted_by(@user),
        limit: @limit
      )
    }
  rescue Timeout::Error => e
    retry
  end
end
