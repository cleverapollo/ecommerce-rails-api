class DigestMailings::Statistics

  # @return [Shop] shop
  attr_accessor :shop

  class << self
    def recalculate_all
      Shop.connected.active.unrestricted.each do |shop|
        new(shop).recalculate
      end
      true
    end
  end

  # @param [Shop] shop
  def initialize(shop)
    self.shop = shop
  end

  # Делает расчет всех данных завершенного дайджеста (не более месяца назад)
  def recalculate
    shop.digest_mailings.finished.where('finished_at > ?', 1.month.ago).each do
    # @type trigger_mailing [DigestMailing]
    |digest_mailing|
      digest_mailing.recalculate_statistic
    end
    true
  end
end
