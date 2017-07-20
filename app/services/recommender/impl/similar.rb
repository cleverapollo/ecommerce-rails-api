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
      # PRICE_DOWN = 1.0

      K_SR = 0.5
      K_CF = 1.0

      def initialize(params)
        super(params)
        @strict_categories = true
      end

      # Выбираем правильные категории для рекоммендера
      def categories_for_promo
        categories_for_query
      end

      def check_params!
        raise Recommendations::IncorrectParams.new('Item ID required for this recommender') if params.item.blank?
        raise Recommendations::IncorrectParams.new('That item has no price') if params.item.price.blank?
      end


      # Товары, из которых выполняются рекомендации.
      # Это те товары, которые принадлежат тем же категориям, что и текущий товар (либо которые указаны в запросе).
      # @return ActiveRecord::Relation
      def items_to_recommend
        # Если в запросе указаны категории, то выбираем товары, входящие хотя бы в одну категорию.
        # Если же не указаны, то точное соответствие категорий.
        result = super.in_categories(categories_for_query, any: (params.categories.try(:any?) ? true : false) ).where.not(id: excluded_items_ids)

        unless params.skip_niche_algorithms

          # Если товар для авто
          # @type item [Item]
          if item.is_auto?
            result = result.where(is_auto: true)

            # (auto_compatibility @> '[{"brand": "BMW"}]' OR auto_compatibility IS NULL)
            if item.auto_compatibility.present?
              result = result.where("(auto_compatibility->'brands' ?| ARRAY[:brand] #{item.auto_compatibility['models'].present? ? "OR auto_compatibility->'models' ?| ARRAY[:model]" : ''})", brand: item.auto_compatibility['brands'], model: item.auto_compatibility['models'])
            end

            if item.auto_vds.present?
              result = result.where('auto_vds && ARRAY[?] OR array_length(auto_vds, 1) IS NULL', item.auto_vds)
            end
          end

          # Если товар детский
          # Тест на дочках показывает снижение продаж. Проверка.
          if item.is_child?

            result = result.where('is_child IS TRUE')
            if item.child_gender.present?
              result = result.where('(child_gender = ? OR child_gender IS NULL)', item.child_gender)
            end
            if item.child_age_min.present?
              result = result.where('(child_age_max >= ? OR child_age_max IS NULL)', item.child_age_min)
            end
            if item.child_age_max.present?
              result = result.where('(child_age_min <= ? OR child_age_min IS NULL)', item.child_age_max)
            end

          end

          if item.is_jewelry?

            subconditions = []
            subconditions << " jewelry_color IS NOT NULL AND jewelry_color = $$#{item.jewelry_color}$$ " if item.jewelry_color.present?
            subconditions << " jewelry_metal IS NOT NULL AND jewelry_metal = $$#{item.jewelry_metal}$$ " if item.jewelry_metal.present?
            subconditions << " jewelry_gem IS NOT NULL AND jewelry_gem = $$#{item.jewelry_gem}$$ " if item.jewelry_gem.present?

            if subconditions.any?
              result = result.where("is_jewelry IS TRUE AND ( #{subconditions.join('OR')} ) ")
            end

          end

          if item.is_cosmetic?
            result = result.where(is_cosmetic: true)

            # Фильтруем похожие ароматы
            if item.cosmetic_perfume_aroma.present?
              result = result.where('cosmetic_perfume_aroma = ? OR cosmetic_perfume_aroma IS NULL', item.cosmetic_perfume_aroma)
            end
            if item.cosmetic_perfume_family.present?
              result = result.where('cosmetic_perfume_family = ? OR cosmetic_perfume_family IS NULL', item.cosmetic_perfume_family)
            end

            # Ногти
            if item.cosmetic_nail?
              result = result.where(cosmetic_nail: true)

              # Фильтруем по типу
              result = result.where(cosmetic_nail_type: item.cosmetic_nail_type) if item.cosmetic_nail_type.present?

              # Для лака добавляет фильтр цвета
              # todo так то лак выбирают близкого по цвету, а не такого же. Спросить у знающих (спросили, вроде как по большой палитре норм).
              if item.cosmetic_nail_type.present? && item.cosmetic_nail_type == 'polish' && item.cosmetic_nail_color.present?
                result = result.where(cosmetic_nail_color: item.cosmetic_nail_color)
              end
            end
          end

        end

        result
      end


      # Выборка товаров, которые необходимо взвесить (отсортировать по CF).
      # Возвращает хеш { ITEMID => SCORE, ITEMID => SCORE }
      # @return Hash
      def items_to_weight

        result = []

        if categories_for_query.empty?
          return result
        end

        # Подмешивание брендов, заполняем по полной, если товар брендовый.
        brand_campaign = Promoting::Brand.brand_campaign_for_item(item, false)
        if brand_campaign
          @only_one_promo = item.brand_downcase
        end

        if result.size < limit

          result += Slavery.on_slave { items_relation_with_price_condition.order(price: :asc).limit(LIMIT_CF_ITEMS).pluck(:id).uniq }
          # result += items_relation_with_price_condition.order(sales_rate: :desc).limit(LIMIT_CF_ITEMS).pluck(:id).uniq
          if result.size < limit
            # Расширяем границы поиска
            # result += items_relation_with_larger_price_condition.where.not(id: result).limit(LIMIT_CF_ITEMS - result.size).pluck(:id)
            result += Slavery.on_slave { items_relation_with_larger_price_condition.where.not(id: result).order(price: :asc).limit(LIMIT_CF_ITEMS - result.size).pluck(:id) }
          end

          # снова не добрали, берем уже все подряд из категории
          if result.size < limit
            result += Slavery.on_slave { items_relation.where.not(id: result).limit(limit - result.size).order(price: :asc).pluck(:id) }
          end
        end

        # Если делаем промо по монобренду, то взвешивать по SR не надо (уже отсортирован)
        # Конвертируем товарную выборку в хеш
        if @only_one_promo
          index_weight(result)
        else
          sr_weight(result)
        end

      end


      # Сортирует товары по связке sales rate и CF weight и возвращает хеш ID=>score
      # @return Hash
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
        (params.categories.try(:any?) ? params.categories : item.category_ids) || []
      end

      def min_date
        1.month.ago.to_date.to_time.to_i
      end

      def items_relation
        relation = items_to_recommend.by_sales_rate
        # relation = items_to_recommend
        if @only_one_promo
          relation = relation.where(brand_downcase: @only_one_promo).where.not(brand_downcase: nil)
        end
        relation
      end

      def items_relation_with_price_condition
        items_relation.where(price: price_range).where('price IS NOT NULL') # is not null нужен для активации индекса
      end

      def items_relation_with_larger_price_condition
        items_relation.where(price: large_price_range).where('price IS NOT NULL') # is not null нужен для активации индекса
      end

    end
  end
end
