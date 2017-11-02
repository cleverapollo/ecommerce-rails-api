module TriggerMailings
  module Triggers
    class ViewedButNotBought < Base
      def condition_happened?
        time_start = (1.day.ago.beginning_of_day)
        time_range = time_start..(1.day.ago.end_of_day)

        # Если недавно был заказ, триггер не шлем.
        # http://y.mkechinov.ru/issue/REES-3399
        return false if user.orders.where('date >= ?', 7.days.ago).exists?

        # Находим товар, который был вчера просмотрен самое большее число раз, но не был куплен
        sessions = Slavery.on_slave { user.active_session_ids(time_start.to_date) }
        actions = ActionCl.where(shop_id: shop.id, session_id: sessions, event: 'view', object_type: 'Item', date: time_range.first.to_date..time_range.last.to_date)
                      .group(:object_id)
                      .order('count(*) DESC')
                      .limit(50)
                      .pluck(:object_id)
        if actions.any?
          @happened_at = ActionCl.where(shop_id: shop.id, session_id: sessions, event: 'view', object_type: 'Item', object_id: actions.first, date: time_range.first.to_date..time_range.last.to_date).limit(1).pluck(:created_at).first
          @source_items = Slavery.on_slave { shop.items.widgetable.where(uniqid: actions) }
          @source_item = @source_items.first
          if @source_item.present?
            return true
          end
        end

        false
      end

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

      def priority
        15
      end
    end
  end
end
