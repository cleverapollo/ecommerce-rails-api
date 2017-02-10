module Recommender
  module Impl
    class AlsoBought < Recommender::Personalized

      K_SR = 1.0
      K_CF = 1.0


      def items_to_recommend
        result = super
        # Только если есть дети с полом и пол только один (чтобы исключить товары противоположного пола)
        if user.try(:children).present? && user.children.is_a?(Array) && user.children.any? && user.children.map { |kid| kid['gender'] }.compact.uniq.count == 1
          result = result.where('(is_child IS TRUE AND (child_gender IS NULL OR child_gender = ?)) OR is_child IS NULL', user.children.map { |kid| kid['gender'] }.compact.uniq.first)
        end
        result
      end

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
        if ids.any? && item && item.category_ids
          _ids = []
          Item.recommendable.where(id: ids).pluck(:id, :category_ids).each do |_element|
            if _element[1].is_a?(Array) && item.category_ids.is_a?(Array) && !(item.category_ids - _element[1]).empty?
            # unless (item.category_ids - _element[1]).empty?
              _ids << _element[0]
            end
          end
          ids = _ids
        end

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

      def items_which_cart_to_analyze
        [item.id]
      end

      def categories_for_promo
        return categories if categories.present?
        @categories_for_promo
      end

      def inject_promotions(result, expansion_only = false)
         #Промо только в категориях товара выдачи
         @categories_for_promo = Item.where(id:result).pluck(:category_ids).flatten.compact.uniq
         super(result, true)
      end

      def inject_random_items(result)
        # Не включать рандомные итемы
        result
      end
    end
  end
end
