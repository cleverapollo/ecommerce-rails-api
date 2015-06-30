module Recommender
  module Impl
    class AlsoBought < Recommender::Personalized

      K_SR = 1.0
      K_CF = 1.0

      def check_params!
        raise Recommendations::IncorrectParams.new('Item ID required for this recommender') if params.item.blank?
      end

      def items_to_weight
        return [] if items_which_cart_to_analyze.none?

        result = OrderItem.where('order_id IN (SELECT DISTINCT(order_id) FROM order_items WHERE item_id IN (?) limit 100)', items_which_cart_to_analyze)
        result = result.where.not(item_id: excluded_items_ids)
        result = result.joins(:item).merge(items_to_recommend) # Эта конструкция подгружает фильтрацию relation для того, чтобы оставить только те товары, которые можно рекомендовать. То есть item_to_recommend тут не добавляет массив товаров
        result = result.where(item_id: Item.in_categories(categories, any: true)) if categories.present? # Рекомендации аксессуаров
        result = result.group(:item_id).order('COUNT(item_id) DESC').limit(LIMIT_CF_ITEMS)
        ids = result.pluck(:item_id)

        # Исключаем товары, которые находятся ровно в том же наборе категорий
        # TODO: в будущем учитывать FMCG и подобные вещи, где товары из одной категории часто покупают вместе, а пока исключаем. Видимо, нужно будет это убрать для отраслевого алгоритма
        if ids.any? && item.categories
          _ids = []
          Item.recommendable.where(id: ids).pluck(:id, :categories).each do |_element|
            unless (item.categories - _element[1]).empty?
              _ids << _element[0]
            end
          end
          ids = _ids
        end

        # Рекомендации аксессуаров
        if categories.present? && ids.size < limit
          ids += items_to_recommend.in_categories(categories, any: true).where.not(id: ids).limit(LIMIT_CF_ITEMS - ids.size).pluck(:id)
        end

        # Для купонных сервисов, где товары покупают по одному, добавляем по просмотрам
        if params.modification == 'coupon' && shop.allow_industrial?
          if ids.size < limit
            # Добираем по просмотрам
            # Получим пользователей, которые просматривали данный товар за последнюю неделю
            users = Action.select(:user_id).where(shop_id: shop.id)
                        .where(item_id: items_which_cart_to_analyze).where('timestamp > ?', 7.days.ago.to_i)
                        .where('view_count > 1').group(:user_id).limit(limit).pluck(:user_id)

            # Получим товары, которые данные пользователи смотрели
            ids += Action.where(user_id: users).limit(limit-ids.size).pluck(:item_id)
          end
        end

        sr_weight(ids)
      end

      # @return Int[]
      def rescore(i_w, cf_weighted)
        i_w.merge(cf_weighted) do |key, sr, cf|
          # подмешиваем оценку SR
          (K_SR * sr.to_f + K_CF * cf.to_f)/(K_CF + K_SR)
        end

      end

      def items_which_cart_to_analyze
        [item.id]
      end

      def categories_for_promo
        return categories if categories.present?
        @categories_for_promo
      end

      def inject_promotions(result)
        result
        # Промо только в категориях товара выдачи
        # @categories_for_promo = Item.where(id:result).pluck(:categories).flatten.compact.uniq
        # super(result)
      end

      def inject_random_items(result)
        # Не включать рандомные итемы
        result
      end
    end
  end
end
