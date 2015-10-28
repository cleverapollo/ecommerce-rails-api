module Recommender
  module Impl
    class BuyingNow < Recommender::Weighted
      LIMIT = 20

      def categories_for_promo
        return categories if categories.present?
        @categories_for_promo
      end

      def inject_promotions(result)
        # Промо только в категориях товара выдачи
        @categories_for_promo = Item.where(id: result).pluck(:categories).flatten.compact.uniq
        super(result, true)
      end

      def items_to_recommend
        if params.modification.present?
          result = super
          if params.modification == 'fashion' || params.modification == 'cosmetic'
            gender_algo = SectoralAlgorythms::VirtualProfile::Gender.new(params.user.profile)
            result = gender_algo.modify_relation_with_rollback(result)
            # Если fashion - дополнительно фильтруем по размеру
            if params.modification == 'fashion'
              size_algo = SectoralAlgorythms::VirtualProfile::Size.new(params.user.profile)
              result = size_algo.modify_relation_with_rollback(result)
            end
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
        result = shop.actions.where('timestamp >= ?', min_date)
        result = result.where(item_id: all_items)
        result = result.group(:item_id)
        result = result.order('SUM(purchase_count) DESC, SUM(view_count) DESC')
        result.limit(params.limit).pluck(:item_id)

      end


    end
  end
end
