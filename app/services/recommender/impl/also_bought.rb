module Recommender
  module Impl
    class AlsoBought < Recommender::Personalized

      attr_accessor :use_cart

      K_SR = 1.0
      K_CF = 1.0


      def items_to_recommend
        result = super

        unless params.skip_niche_algorithms

          # Детский алгоритм
          if shop.has_products_kids?

            # Если у юзера есть дети
            if params.profile.try(:children).present? && params.profile.children.is_a?(Array) && params.profile.children.any?

              # Если у юзера дети одного пола, тогда имеет смысл исключать товары противоположного пола
              if params.profile.children.map { |kid| kid['gender'] }.compact.uniq.count == 1
                result = result.where('(is_child IS TRUE AND (child_gender IS NULL OR child_gender = ?)) OR is_child IS NULL', params.profile.children.map { |kid| kid['gender'] }.compact.uniq.first)
              end
            end
          end


          # Взрослая одежда
          if shop.has_products_fashion?

          end


          # Ювелирка
          result = apply_jewelry_industrial_filter result

        end

        result
      end

      def check_params!
        raise Recommendations::IncorrectParams.new('Item ID required for this recommender') if params.item.blank?
      end

      def items_to_weight
        return [] if items_which_cart_to_analyze.none?
        ids = []

        # Добавляем рекомендуемые товары самим магазином в выборку
        ids += Item.where(shop_id: params.shop.id, uniqid: params.item.shop_recommend).widgetable.recommendable.pluck(:id) if params.item.present? && params.item.shop_recommend.present?

        if use_cart
          ids += ClientCart.connection.select_values(ActiveRecord::Base.send(:sanitize_sql_array, [
              'SELECT item_id FROM client_carts, jsonb_array_elements_text(items) AS item_id WHERE shop_id = :shop_id AND item_id::bigint != :item_id AND items @> \'[:item_id]\'::jsonb GROUP BY 1',
              shop_id: params.shop.id, item_id: params.item_id
          ]))
        else
          # DISTINCT вынесен в отдельный подзапрос, т.к. для 100 записей он работает в 1000 раз быстрее, чем для всей таблицы
          result = OrderItem.where('order_id IN (SELECT DISTINCT(order_id) FROM (SELECT order_id FROM order_items WHERE item_id IN (?) limit 100) AS t)', items_which_cart_to_analyze)
          result = result.where.not(item_id: excluded_items_ids)
          result = result.joins(:item).merge(items_to_recommend) # Эта конструкция подгружает фильтрацию relation для того, чтобы оставить только те товары, которые можно рекомендовать. То есть item_to_recommend тут не добавляет массив товаров
          # todo тут долгий запрос, item уже подключена через join
          result = result.where(item_id: Item.in_categories(categories, any: true)) if categories.present? # Рекомендации аксессуаров
          result = result.group(:item_id).order('COUNT(item_id) DESC').limit(LIMIT_CF_ITEMS)

          # Получаем товары из заказов
          ids += Slavery.on_slave { result.pluck(:item_id) }
        end

        # Если указан фильтр максимальной цены, оставляем только те ID, которые соответствуют этой цене
        if params.max_price_filter
          appropriate_ids = Slavery.on_slave { items_to_recommend.where(id: ids).where('price IS NOT NULL AND price > ?', params.max_price_filter).pluck(:id) }
          if appropriate_ids.any?
            # Сохраняя сортировку
            ids = ids - (ids - appropriate_ids)
          end
        end

        # Исключаем товары, которые находятся ровно в том же наборе категорий
        # TODO: в будущем учитывать FMCG и подобные вещи, где товары из одной категории часто покупают вместе, а пока исключаем. Видимо, нужно будет это убрать для отраслевого алгоритма
        if ids.any? && item && item.category_ids
          _ids = []
          Slavery.on_slave do
            Item.recommendable.where(id: ids).pluck(:id, :category_ids).each do |_element|
              if _element[1].nil? || _element[1].is_a?(Array) && item.category_ids.is_a?(Array) && !(item.category_ids - _element[1]).empty?
              # unless (item.category_ids - _element[1]).empty?
                _ids << _element[0]
              end
            end
          end
          ids = _ids
        end

        # Рекомендации аксессуаров
        if categories.present? && ids.size < limit
          ids += Slavery.on_slave { items_to_recommend.in_categories(categories, any: true).where.not(id: ids).limit(LIMIT_CF_ITEMS - ids.size).pluck(:id) }
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
