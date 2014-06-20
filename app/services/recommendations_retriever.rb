class RecommendationsRetriever
  attr_accessor :shop
  attr_accessor :limit
  attr_accessor :user
  attr_accessor :mahout_service
  attr_accessor :item_ids

  attr_accessor :recommendations

  def initialize(shop, limit, item_ids = nil)
    @shop, @limit = shop, limit
    @mahout_service = MahoutService.new
    @item_ids = item_ids

    begin
      Timeout::timeout(2) {
        @mahout_service.open
      }
    rescue Timeout::Error => e
      retry
    end
  end

  def for(user)
    @user = user
    result = []

    result = result + interesting(self.limit)

    if result.count < self.limit
      #result = result + (item_ids - result).sample(self.limit - result.count)
    end

    Item.where(id: result).map do |item|
      item.url = UrlHelper.add_param(item.url, utm_source: 'rees46')
      item.url = UrlHelper.add_param(item.url, utm_meta: 'email_digest')
      item.url = UrlHelper.add_param(item.url, utm_campaign: 'interesting')
      item
    end
  end

  def interesting(limit)
    mahout_ids = []
    begin
      Timeout::timeout(2) {
        mahout_ids = mahout_service.user_based(user.id, shop.id, nil,
          include: item_ids,
          exclude: Recommender::Base.exclude_in_recommendations(user.id, shop.id),
          limit: limit
        )
      }
    rescue Timeout::Error => e
      retry
    end
    mahout_ids
  end
end
