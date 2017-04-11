class ReputationPublisher
  class << self
    def perform
      Reputation.on_moderation.where('updated_at < ?', 2.days.ago).update_all(status: Reputation::STATUSES[:published], published_at: Time.now)
    end
  end
end
