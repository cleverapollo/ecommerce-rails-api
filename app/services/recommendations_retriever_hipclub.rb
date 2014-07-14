class RecommendationsRetrieverHipclub
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
      result = result + more((item_ids - result.map(&:id)), self.limit - result.count)
    end

    result
  end

  def more(ids, limit)
    Item.where(id: ids.sample(limit)).map{|item| item.mail_recommended_by = 'popular'; item }
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
    Item.where(id: mahout_ids).map{|item| item.mail_recommended_by = 'interesting'; item }
  end
end
