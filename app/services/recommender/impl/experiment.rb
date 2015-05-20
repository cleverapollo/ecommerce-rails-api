module Recommender
  module Impl
    class Experiment < Recommender::Base
      include ItemInjector
      include CfHelper

      LIMIT = 20

      K_SR = 1.0
      K_CF = 1.0

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

        result
      end


      # @return Int[]
      def recommended_ids


        # получим товары для взвешивания
        i_w = items_to_weight

        # Взвешиваем махаутом
        cf_weighted = cf_weight(i_w)

        # Взвешиваем по SR
        sr_weighted = sr_weight(i_w)

        # Рассчитываем финальную оценку
        result = sr_weighted.merge(cf_weighted) do |key, sr, cf|
          (K_SR*sr.to_f + K_CF*cf.to_f)/(K_CF+K_SR)
        end.sort do |x, y|
          # сортируем по вычисленной оценке
          x= x[1].to_i
          y= y[1].to_i
          y<=>x
        end

        # Ограничиваем размер вывода
        result = if result.size > params.limit
                   result.take(params.limit)
                 else
                   result
                 end

        # оставим только id товаров
        result = result.to_h.keys

        inject_items(result)

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
