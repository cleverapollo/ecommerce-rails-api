module Recommender
  module Impl
    class SeeAlso < Recommender::Personalized

      K_SR = 1.0
      K_CF = 1.0


      def items_to_recommend
        result = super

        # Только если есть дети с полом и пол только один (чтобы исключить товары противоположного пола)
        if !params.skip_niche_algorithms && user.try(:children).present? && user.children.is_a?(Array) && user.children.any? && user.children.map { |kid| kid['gender'] }.compact.uniq.count == 1
          result = result.where('(is_child IS TRUE AND (child_gender IS NULL OR child_gender = ?)) OR is_child IS NULL', user.children.map { |kid| kid['gender'] }.compact.uniq.first)
        end

        # Основная фильтрация
        unless params.skip_niche_algorithms
          result = apply_jewelry_industrial_filter result
        end

        result
      end


      def items_to_weight
        return [] if items_which_cart_to_analyze.none?

        # DISTINCT вынесен в отдельный подзапрос, т.к. для 100 записей он работает в 1000 раз быстрее, чем для всей таблицы
        result = OrderItem.where('order_id IN (SELECT DISTINCT(order_id) FROM (SELECT order_id FROM order_items WHERE item_id IN (?) limit 100) AS t)', items_which_cart_to_analyze)
        result = result.where.not(item_id: excluded_items_ids)
        result = result.joins(:item).merge(items_to_recommend) # Эта конструкция подгружает фильтрацию relation для того, чтобы оставить только те товары, которые можно рекомендовать. То есть item_to_recommend тут не добавляет массив товаров
        # todo тут долгий запрос, item уже подключена через join
        result = result.where(item_id: Item.in_categories(categories, any: true)) if categories.present? # Рекомендации аксессуаров
        result = result.group(:item_id).order('COUNT(item_id) DESC').limit(LIMIT_CF_ITEMS)
        ids = []

        # Добавляем рекомендуемые товары самим магазином в выборку
        ids += Item.where(shop_id: params.shop.id, uniqid: params.item.shop_recommend).widgetable.recommendable.pluck(:id) if params.item.present? && params.item.shop_recommend.present?

        # Получаем товары из заказов
        ids += result.pluck(:item_id)

        # Если указан фильтр максимальной цены, оставляем только те ID, которые соответствуют этой цене
        if params.max_price_filter
          appropriate_ids = items_to_recommend.where(id: ids).where('price IS NOT NULL AND price > ?', params.max_price_filter).pluck(:id)
          if appropriate_ids.any?
            # Сохраняя сортировку
            ids = ids - (ids - appropriate_ids)
          end
        end

        # Mark: не исключаем товары, которые находятся ровно в том же наборе категорий, в отличие от AlsoBought

        # Рекомендации аксессуаров
        if categories.present? && ids.size < limit
          ids += items_to_recommend.in_categories(categories, any: true).where.not(id: ids).limit(LIMIT_CF_ITEMS - ids.size).pluck(:id)
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

      def categories_for_promo
        return categories if categories.present?
        @categories_for_promo
      end


      def check_params!
      end

      def items_which_cart_to_analyze
        params.cart_item_ids
      end

      def inject_promotions(result, expansion_only = false)
        # Не надо включать промо
        result
      end

      def inject_random_items(result)
        # Не включать рандомные итемы
        result
      end

    end
  end
end
