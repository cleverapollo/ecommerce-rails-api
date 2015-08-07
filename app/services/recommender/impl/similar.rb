module Recommender
  module Impl
    class Similar < Recommender::Personalized

      # Логика:
      # Пытаемся найти товары в интервале от 0.85 до 1.25 цены текущего товара.
      # Если не находим, то расширяем интервал от 0.5 до 1.5 цены текущего товара.
      # Не рекомендуем товары без цены. Не можем рекомендовать для товара без цены.

      LARGE_PRICE_UP = 1.5
      PRICE_UP = 1.25
      LARGE_PRICE_DOWN = 0.5
      PRICE_DOWN = 0.85

      K_SR = 1.0
      K_CF = 1.0

      # Выбираем правильные категории для рекоммендера
      def categories_for_promo
        categories_for_query
      end

      def check_params!
        raise Recommendations::IncorrectParams.new('Item ID required for this recommender') if params.item.blank?
        raise Recommendations::IncorrectParams.new('That item has no price') if params.item.price.blank?
      end

      def items_to_recommend
        super.where(id:Item.in_categories(categories_for_query).where(shop_id:shop.id)).where.not(id: item.id)
      end

      def items_to_weight

        result = []

        if categories_for_query.empty?
          return result
        end

        advertiser = Promoting::Brand.find_by_item(item)
        if advertiser.any?
          advertiser.each do |advertiser_id|
            break if result.size >= limit
            result += Advertiser.find(advertiser_id).get_from_categories(shop.id, item.categories, excluded_items_ids, limit)
          end
        end

        if result.size <limit

          # ТОРМОЗИИИИИИИТ
          result += shop.actions.where(item_id: items_relation_with_price_condition).
              where('timestamp > ?', min_date).
              group(:item_id).by_average_rating.
              limit(LIMIT_CF_ITEMS).pluck(:item_id)

          if result.size < limit
            # Расширяем границы поиска
            result += items_relation_with_larger_price_condition.where.not(id: result).limit(LIMIT_CF_ITEMS - result.size).pluck(:id)
          end

          
          
          # снова не добрали, берем уже все подряд из категории
          if result.size < limit
            result += items_relation.where.not(id: result).limit(limit - result.size).order(price: :desc).pluck(:id)
          end
        end
        # взвешиваем по SR
        sr_weight(result)

      end

      def rescore(i_w, cf_weight)
        result = i_w.merge(cf_weight) do |key, sr, cf|
          # подмешиваем оценку SR
          (K_SR * sr.to_f + K_CF * cf.to_f)/(K_CF + K_SR)
        end
        result
      end

      def inject_random_items(result)
        # Не подмешивать случайные товары
        result
      end


      def price_range
        (item.price * PRICE_DOWN).to_i..(item.price * PRICE_UP).to_i
      end

      def large_price_range
        (item.price * LARGE_PRICE_DOWN).to_i..(item.price * LARGE_PRICE_UP).to_i
      end

      def categories_for_query
        params.categories.try(:any?) ? params.categories : item.categories
      end

      def min_date
        1.month.ago.to_date.to_time.to_i
      end

      def items_relation
        items_to_recommend.by_sales_rate
      end

      def items_relation_with_price_condition
        items_relation.where(price: price_range)
      end

      def items_relation_with_larger_price_condition
        items_relation.where(price: large_price_range)
      end

    end
  end
end
