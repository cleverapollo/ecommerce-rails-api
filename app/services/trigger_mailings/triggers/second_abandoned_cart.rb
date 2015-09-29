module TriggerMailings
  module Triggers
    ##
    # Базовый класс для триггеров "брошенная корзина"
    #
    class SecondAbandonedCart < Base
      # Отправляем, если товар был положен в корзину больше часа, но меньше четырех часов назад.
      def trigger_time_range
        (28.hours.ago..24.hours.ago)
      end

      def priority
        100
      end

      def appropriate_time_to_send?
        true
      end

      def condition_happened?
        # Проверка что последное письмо отправили киленту 1 дня назад
        return false if !trigger_time_range.cover?(client.last_trigger_mail_sent_at)

        # Находим вчерашную не открытую брошеную корзину
        trigger_mailing = TriggerMailing.where(shop: shop).find_by(trigger_type: 'abandoned_cart')
        unopened_abandoned_cart =  TriggerMail.where(shop: shop).where(created_at: trigger_time_range).where(opened: false).where(trigger_mailing_id: trigger_mailing.id).where(client_id: client.id)
        return false if !unopened_abandoned_cart

        # Находим товар, который был положен в корзину в нужном периоде, но не был из нее удален или куплен
        user.actions.where(shop: shop).carts.where(cart_date: trigger_time_range).order(cart_date: :desc).each do |action|
          @happened_at = action.cart_date
          @source_item = action.item

          if @source_item.present? && @source_item.widgetable?
            return true
          end
        end
        false
      end

      # Рекомендации для второй брошенной корзины
      def recommended_ids(count)
        params = OpenStruct.new(
          shop: shop,
          user: user,
          item: source_item,
          limit: count,
          recommend_only_widgetable: true,
          locations: source_item.locations
        )

        # Сначала похожие товары
        result = Recommender::Impl::Similar.new(params).recommended_ids

        # Затем интересные
        if result.count < count
          result += Recommender::Impl::Interesting.new(params.tap { |p|
            p.limit = (count - result.count)
            p.exclude = result
          }).recommended_ids
        end

        # Потом популярные
        if result.count < count
          result += Recommender::Impl::Popular.new(params.tap { |p|
            p.limit = (count - result.count)
            p.exclude = result
          }).recommended_ids
        end

        result
      end
    end
  end
end
