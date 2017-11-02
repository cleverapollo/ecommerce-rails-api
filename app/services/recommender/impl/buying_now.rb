module Recommender
  module Impl
    class BuyingNow < Recommender::Weighted
      LIMIT = 20

      def categories_for_promo
        return categories if categories.present?
        @categories_for_promo
      end

      def inject_promotions(result, expansion_only = false)
        # Промо только в категориях товара выдачи
        @categories_for_promo = Item.where(id: result).pluck(:category_ids).flatten.compact.uniq
        super(result, true)
      end

      def items_to_recommend
        # Note: потенциальный косяк для, например, ювелирки. Если смотрим категорию "кольца", то отраслевой не будет применен
        # и мы не сможем отфильтровать кольца по размеру. Это плохо. Но применять его же нельзя для одежды или товаров для
        # животных - если человек зашел в категорию корма для кошек, а мы знаем, что у него собака, то отфильтровав выдачу по собакам, получим
        # пустой результат.
        # Поэтому нужно доработать так, что в случае отсутствия категорий работают все фильтры, а в случае наличия категории
        # работают только избранный набор, не приводящий к исключению всех товаров категории.
        apply_industrial_filter(super)
      end

      # Products, bought for last 24 hours sorted by amount of purchases
      def items_to_weight
        result = shop.order_items.where(item: items_to_recommend.where.not(id: excluded_items_ids))
        result = result.where(order: shop.orders.where('date >= ?', 1.day.ago))
        result = Slavery.on_slave { result.group(:item_id).count(:item_id) }
        # Вытаскиваем маржинальность
        margins = items_to_recommend.where(id: result.map { |k,v| k }).pluck(:id, :price_margin, :category_ids)
        # Накладываем маржинальность на продаваемость
        result = result.map do |id, count|
          margin_row = margins.select { |x| x[0] == id }.first
          if !margin_row.nil? && !margin_row[1].nil?
            margin = margin_row[1].to_f
          else
            margin = 10.0
          end
          [id, count.to_f * margin ]
        end
        # Сортируем, оставляем только идентификаторы и
        result = result.sort{ |a,b| a[1] <=> b[1] }.reverse.map {|x| x[0]}

        # Убираем товары из дублирующихся категорий
        result_filtered = result.uniq { |x| x[1] }

        # Если после фильтрации результатов оказалось столько, сколько запрошено, используем их
        if result_filtered.count >= params.limit
          result = result_filtered
        end

        # Берем столько, сколько нужно
        result = result.take(params.limit)

        # Если результатов нет, то показываем затронутые сегодня товары, покупавшиеся ранее
        unless result.any?
          uniqid = ActionCl.where(event: 'purchase', shop_id: shop.id, object_type: 'Item')
                       .where('date >= ?', Date.yesterday)
                       .group(:object_id).order('count(*) DESC')
                       .limit(params.limit)
                       .pluck(:object_id)
          result = Slavery.on_slave { shop.items.recommendable.where(uniqid: uniqid).where.not(id: excluded_items_ids).limit(params.limit).pluck(:id) }
        end

        result

      end


    end
  end
end
