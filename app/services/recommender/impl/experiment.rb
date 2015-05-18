module Recommender
  module Impl
    class Experiment < Recommender::Base
      LIMIT = 20
      LIMIT_CF_ITEMS = 1000

      K_SR = 1
      K_CF = 1


      # @return Int[]
      def recommended_ids

        i_w = items_to_weight

        cf_weighted = {}
        if i_w.any?
          ms = MahoutService.new
          ms.open
          cf_result = ms.item_based_weight(params.user.id,
                                           weight: i_w,
                                           limit: LIMIT_CF_ITEMS)
          ms.close

          delta = 1.0/cf_result.size
          cur_cf_pref = 1.0
          cf_result.each do |cf_item|
            cf_weighted[cf_item] = (cur_cf_pref.to_f * 10000).to_i
            cur_cf_pref-=delta
          end
        end

        sr_weighted = sr_weight(i_w)

        result = sr_weighted.merge(cf_weighted) do |key, sr, cf|
          (K_SR*sr + K_CF*cf)/(K_CF+K_SR)
        end.sort { |x,y| x[1]<=>y[1] }.to_h

        result = if result.size > params.limit
                   i_w.sample(params.limit)
                 else
                   i_w
                 end


        result
      end

      def items_to_recommend
        if shop.sectoral_algorythms_available?
          result = super
          if shop.category.wear?
            gender = SectoralAlgorythms::Wear::Gender.calculate_for(user, shop: shop)
            result = result.by_ca(gender: gender)
            # TODO: фильтрация по размерам одежды
          end
          result

        else
          super
        end
      end

      def inject_promotions(result_ids)
        Promotion.find_each do |promotion|
          if promotion.show?(shop: shop, item: item, categories: categories)
            promoted_item_id = promotion.scope(items_to_recommend.in_categories(categories)).where.not(id: result_ids).limit(1).first.try(:id)
            if promoted_item_id.present?
              result_ids[0] = promoted_item_id
            end
          end
        end

        result_ids
      end

      def items_to_weight
        # Разные запросы в зависимости от присутствия или отсутствия категории
        # Используют разные индексы
        in_category = false
        relation = if categories.try(:any?)
                     in_category = true
                     popular_in_category
                   else
                     popular_in_all_shop
                   end

        # Находим отсортированные товары
        result = relation.where('sales_rate is not null and sales_rate > 0').order(sales_rate: :desc)
                     .limit(LIMIT_CF_ITEMS).pluck(:id)

        unless shop.strict_recommendations?
          # Если товаров недостаточно - рандом
          result = inject_random_items(result) unless in_category
        end

        # Добавляем продвижение брендов
        result = inject_promotions(result)

        result
      end

      # Популярные по всему магазину
      # @returns - ActiveRecord List of Action[]
      def popular_in_all_shop
        items_to_recommend.where.not(id: excluded_items_ids)
      end

      # Популярные в конкретной категории
      def popular_in_category
        popular_in_all_shop.in_categories(params.categories)
      end

      def sr_weight(items)
        shop.items.where(id: items).pluck(:id, :sales_rate).to_h
      end
    end
  end
end
