class DigestMailings::Statistics

  class << self
    def recalculate_all
      DigestMailing.finished.where('finished_at > ? AND finished_at < ?', 1.month.ago, 1.day.ago).each do |digest_mailing|
        digest_mailing.recalculate_statistic
      end
      true
    end

    def recalculate_today
      DigestMailing.finished.where('finished_at >= ?', 1.day.ago).each do |digest_mailing|
        digest_mailing.recalculate_statistic
      end
      true
    end
  end

end
