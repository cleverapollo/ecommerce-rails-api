class RecommendationsRequest < ActiveRecord::Base
  validates :shop_id, presence: true
  validates :branch_id, presence: true
  validates :recommender_type, presence: true
  validates :recommendations_count, presence: true
  validates :recommendations_count, presence: true
  validates :duration, presence: true
  validates :user_id, presence: true

  class << self
    def report
      recommendations_request = new
      time_start = Time.now
      yield recommendations_request
      time_finish = Time.now
      recommendations_request.duration = time_finish - time_start
      recommendations_request.save!
    end
  end

  def recommendations=ids
    self.recommended_ids = ids
    self.recommendations_count = ids.size
  end

  def shop=s
    self.shop_id = s.id
    self.branch_id = s.branch_id
  end

  def user=u
    self.user_id = u.id
  end

  def session=s
    self.session_code = s.code if s.present?
  end
end
