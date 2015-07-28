module Recommender
  module Impl
    class BuyingNow < Recommender::Weighted
      LIMIT = 20

      def categories_for_promo
        return categories if categories.present?
        @categories_for_promo
      end

      def inject_promotions(result)
        result
        # # Промо только в категориях товара выдачи
        # @categories_for_promo = Item.where(id:result).pluck(:categories).flatten.compact.uniq
        # super(result)
      end

      def items_to_recommend
        if params.modification.present?
          result = super
          if params.modification == 'fashion'
            # gender = SectoralAlgorythms::Wear::Gender.value_for(user, shop: shop, current_item: item)
            # result = result.by_ca(gender: gender)

            # фильтрация по размерам одежды
            #if item && item.custom_attributes['sizes'].try(:first).try(:present?)
            #  result = result.by_ca(sizes: item.custom_attributes['sizes'])
            #end
          end
          result
        else
          super
        end
      end

      def items_to_weight
        min_date = 1.day.ago.to_i

        all_items = items_to_recommend.where.not(id: excluded_items_ids)

        # Выводит топ товаров за последние сутки.
        # Те, что чаще покупаются - будут выше.
        # Если покупок нет, все равно будет работать.
        # result = shop.actions.where('timestamp >= ?', min_date)
        # result = result.where(item_id: all_items)
        # result = result.group(:item_id)
        # result = result.order('SUM(purchase_count) DESC, SUM(view_count) DESC')
        # result.limit(LIMIT).pluck(:item_id)

        result = OrderItem.where(order_id: Order.where(shop_id: shop.id).limit(LIMIT * 10) ).where(item_id: all_items).order(id: :desc).limit(LIMIT).pluck(:item_id)

      end


    end
  end
end
