module TriggerMailings
  module Triggers
    ##
    # Триггер "Брошенный просмотр категории"
    #
    class AbandonedCategory < Base
      # Интервал времени на событие – 48 часов
      def trigger_time_range
        (48.hours.ago..60.minutes.ago)
      end

      def priority
        13
      end

      def appropriate_time_to_send?
        true
      end

      # Если есть просмотр категории
      # При этом нет просмотров товаров в этой категории
      # При этом нет покупок за этот период
      # @return Boolean
      def condition_happened?
        # Если недавно был заказ, триггер не шлем.
        # http://y.mkechinov.ru/issue/REES-3399
        return false if user.orders.where('date >= ?', 7.days.ago).exists?

        # Получаем недавно просмотренные категории
        additional_info[:categories] = ActionCl.where(shop_id: shop.id, object_type: ItemCategory, event: 'view', session_id: user.active_session_ids(trigger_time_range.first.to_date)).in_date(trigger_time_range).pluck(:object_id)
        return false if additional_info[:categories].blank?

        # Ищем товары, которые смотрел юзер
        items = ActionCl.where(shop_id: shop.id, object_type: Item, event: 'view').in_date(trigger_time_range).pluck(:object_id)
        # Если товаров нет, триггер сроботал, если есть категории
        if items.blank?
          additional_info[:categories] = Slavery.on_slave { shop.item_categories.where(external_id: additional_info[:categories]).pluck(:external_id) }
          return additional_info[:categories].present?
        end

        # Убираем категории просмотренных товаров и, если останутся категории, в которых не смотрели товаров, значит триггер сработал
        items_categories = Slavery.on_slave { shop.items.where(uniqid: items).pluck(:category_ids).flatten.compact }
        filtered_category_external_ids = additional_info[:categories] - items_categories

        # Если остались категории, в которых не смотрели товары
        if filtered_category_external_ids.any?
          additional_info[:categories] = Slavery.on_slave { shop.item_categories.where(external_id: filtered_category_external_ids).pluck(:external_id) }
          return true if additional_info[:categories].any?
        end

        false
      end

      # Рекомендации:
      # - популярные в категориях
      def recommended_ids(count)

        params = OpenStruct.new(
          shop: shop,
          user: user,
          limit: count,
          recommend_only_widgetable: true,
          categories: additional_info[:categories],
          locations: client.location.present? ? [client.location] : nil
        )

        Recommender::Impl::Popular.new(params).recommended_ids
      end
    end
  end
end
