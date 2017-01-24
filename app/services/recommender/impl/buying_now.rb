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
        super
      end

      # Products, bought for last 24 hours sorted by amount of purchases
      def items_to_weight
        result = shop.order_items.where(item: items_to_recommend.where.not(id: excluded_items_ids))
        result = result.where(order: shop.orders.where('date >= ?', 1.day.ago))
        result = result.group(:item_id).count(:item_id)
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
          result = shop.actions.where('timestamp >= ?', 1.day.ago.to_i).select(:item_id)
          result = result.where(item_id: items_to_recommend.where.not(id: excluded_items_ids))
          result = result.group(:item_id)
          result = result.order('SUM(purchase_count) DESC, SUM(view_count) DESC')
          result = result.limit(params.limit).pluck(:item_id)
        end

        result

      end


    end
  end
end
