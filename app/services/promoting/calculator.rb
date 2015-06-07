module Promoting
  class Calculator

    class << self

      # Расчет стоимости рекламы за прошлый день
      def previous_days
        AdvertiserStatistic.where(date: Date.yesterday).includes(:advertiser).find_each do |row|

          # Считаем цену
          cost = row.advertiser.cpm.to_f / 1000.0 * row.views.to_f

          # Отмечаем вчерашний день
          row.update cost: cost

          # Вычитаем сумму из баланса рекламодателя
          row.advertiser.change_balance(-cost)

        end
      end

    end

  end
end
