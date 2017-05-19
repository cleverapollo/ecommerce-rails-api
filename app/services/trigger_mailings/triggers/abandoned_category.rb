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
        Slavery.on_slave do
          # Если недавно был заказ, триггер не шлем.
          # http://y.mkechinov.ru/issue/REES-3399
          return false if user.orders.where('date >= ?', 7.days.ago).exists?

          if (elements = SubscribeForCategory.where(shop: shop, user: user).where(subscribed_at: trigger_time_range).pluck(:item_category_id)).any?
            additional_info[:categories] = ItemCategory.where(id: elements)
            if additional_info[:categories].any?
              unless user.orders.where(shop: shop).where('date > ?', trigger_time_range.first).exists?
                touched_product_ids_during_period = user.actions.where(shop: shop).where('timestamp >= ?', trigger_time_range.first.to_i).pluck(:item_id).uniq
                if touched_product_ids_during_period.any?
                  # Убираем категории просмотренных товаров и, если останутся категории, в которых не смотрели товаров, значит триггер сработал и
                  # это ключевые категории
                  categories = shop.items.where(id: touched_product_ids_during_period).pluck(:category_ids).flatten.compact
                  filtered_category_external_ids = additional_info[:categories].pluck(:external_id) - categories
                  if filtered_category_external_ids.any?
                    additional_info[:categories] = shop.item_categories.where(external_id: filtered_category_external_ids)
                    return true if additional_info[:categories].any?
                  end
                else
                  # Нет просмотров, значит триггер работает
                  return true
                end
              end
            end
          end
        end
        false
      end

      # Рекомендации:
      # - популярные в категориях
      def recommended_ids(count)
        result = []

        additional_info[:categories].each do |category|
          next if result.count >= count

          params = OpenStruct.new(
            shop: shop,
            user: user,
            limit: count,
            recommend_only_widgetable: true,
            categories: [category.external_id],
            locations: client.location.present? ? [client.location] : nil
          )

          result += Recommender::Impl::Popular.new(params.tap do |p|
            p.limit = (count - result.count)
            p.exclude = result
          end).recommended_ids
        end

        result
      end
    end
  end
end
