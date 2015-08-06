module Recommender
  module Impl
    class Popular < Recommender::Personalized

      K_SR = 1.0
      K_CF = 1.0

      def categories_for_promo
        return categories if categories.present?
        @categories_for_promo
      end

      def inject_promotions(result)
        if categories.try(:any?)
          # Промо только в категориях товара выдачи
          @categories_for_promo = Item.where(id:result).pluck(:categories).flatten.compact.uniq
          super(result)
        else
          result
        end
      end

      def items_to_weight
        # Разные запросы в зависимости от присутствия или отсутствия категории
        # Используют разные индексы
        relation = if categories.try(:any?)
                     popular_in_category
                   else
                     popular_in_all_shop
                   end

        # Находим отсортированные товары
        result = relation.by_sales_rate.limit(LIMIT_CF_ITEMS).pluck(:id, :sales_rate, :categories)


        result.to_a.map { |value| [value[0], {sales_rate: value[1], categories:value[2]}] }.to_h
      end


      # @return Int[]
      def rescore(items_weighted, cf_weighted)
        items_weighted.merge!(cf_weighted) do |_, weighted_sr_item, cf|
          # подмешиваем оценку CF
          {sales_rate: (K_SR * weighted_sr_item[:sales_rate].to_f + K_CF * cf.to_f)/(K_CF+K_SR), categories:weighted_sr_item[:categories]}
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


      def items_to_recommend
        if params.modification.present?
          result = super
          if params.modification == 'fashion'
            if categories.try(:any?)
              # в категории
            else
              # на главной
              gender_algo = SectoralAlgorythms::Wear::Gender.new(params.user)
              result = gender_algo.modify_relation(result)
            end
          end
          result
        else
          super
        end
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


    end
  end
end
