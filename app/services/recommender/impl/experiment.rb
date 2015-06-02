module Recommender
  module Impl
    class Experiment < Recommender::Impl::Popular

      def items_to_weight
        # Разные запросы в зависимости от присутствия или отсутствия категории
        # Используют разные индексы
        relation = if categories.try(:any?)
                     popular_in_category
                   else
                     popular_in_all_shop
                   end

        # Находим отсортированные товары
        result = relation.select(:id, ).where('sales_rate is not null and sales_rate > 0').order(sales_rate: :desc)
                     .limit(LIMIT_CF_ITEMS).pluck(:id, :sales_rate, :categories)


        result.to_a.map { |value| [value[0], {sales_rate: value[1], categories:value[2]}] }.to_h
      end


      # @return Int[]
      def rescore(items_weighted, cf_weighted)
        items_weighted.merge!(cf_weighted) do |_, weighted_sr_item, cf|
          # подмешиваем оценку CF
          {sales_rate: (K_SR*weighted_sr_item[:sales_rate].to_f + K_CF*cf.to_f)/(K_CF+K_SR), categories:weighted_sr_item[:categories]}
        end

        items_weighted = items_weighted.sort do |x, y|
          # сортируем по вычисленной оценке
          x= x[1][:sales_rate].to_f
          y= y[1][:sales_rate].to_f
          y<=>x
        end

        # Уникализируем категории
        items_with_uniq_categories = {}
        items_weighted.each do |id, item|
          break if items_with_uniq_categories.size >= params.limit
          items_with_uniq_categories[item[:categories].first] ||= []

          # берем только первую указанную категорию, чтобы избежать дублирование товара
          items_with_uniq_categories[item[:categories].first].push({id => item[:sales_rate]})
        end

        # сколько брать из каждой категории
        from_category = params.limit / items_with_uniq_categories.size

        result = {}

        # Преобразуем к корректному формату для рекоммендера
        items_with_uniq_categories.each do |_, cat_items|
          cat_items.take(from_category).flatten.each do |ci|
            result.merge!(ci)
          end
        end

        result
      end


    end
  end
end
