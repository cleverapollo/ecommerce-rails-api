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
        # Сортируем по количеству покупок в порядке убывания
        result = group(:item_id).count(:item_id).sort{ |a,b| a[1] <=> b[1] }.reverse.map {|x| x[0]}.limit(params.limit)

        # Если результатов нет, то показываем затронутые сегодня товары, покупавшиеся ранее
        unless result.any?
          result = shop.actions.where('timestamp >= ?', 1.day.ago.to_i)
          result = result.where(item_id: items_to_recommend.where.not(id: excluded_items_ids))
          result = result.group(:item_id)
          result = result.order('SUM(purchase_count) DESC, SUM(view_count) DESC')
          result.limit(params.limit).pluck(:item_id)
        end

        result

      end


    end
  end
end
