class AudienceSegmentStatistic < ActiveRecord::Base
  belongs_to :shop
  validates :shop_id, :overall, :activity_a, :activity_b, :activity_c, :recalculated_at, :triggers_overall, :triggers_activity_a, :triggers_activity_b, :triggers_activity_c, :digests_overall, :digests_activity_a, :digests_activity_b, :digests_activity_c, :presence => true
  after_initialize :init_defaults


  class << self

    def fetch(shop)
      s = self.find_by shop_id: shop.id
      unless s
        s = self.create! shop_id: shop.id
      end
      s
    end

  end


  private

  def init_defaults
    self.recalculated_at ||= Date.current
  end

end
