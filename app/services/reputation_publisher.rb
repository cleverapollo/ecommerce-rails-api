class ReputationPublisher

  class << self
    def perform
      CustomLogger.logger.info("START: ReputationPublisher::perform")

      Reputation.on_moderation.where('updated_at < ?', 2.days.ago).update_all(status: Reputation::STATUSES[:published], published_at: Time.now)

      CustomLogger.logger.info("STOP: ReputationPublisher::perform")
    end
  end
end
