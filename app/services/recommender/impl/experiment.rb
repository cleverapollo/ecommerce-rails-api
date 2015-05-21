module Recommender
  module Impl
    class Experiment < Recommender::Personalized

      K_SR = 1.0
      K_CF = 1.0

      def check_params!
        raise Recommendations::IncorrectParams.new('Item ID required for this recommender') if params.item.blank?
      end

      def items_to_weight
        return [] if items_which_cart_to_analyze.none?

        result = OrderItem.where('order_id IN (SELECT DISTINCT(order_id) FROM order_items WHERE item_id IN (?) limit 10)', items_which_cart_to_analyze)
        result = result.where.not(item_id: excluded_items_ids)
        result = result.joins(:item).merge(items_to_recommend)
        result = result.where(item_id: Item.in_categories(categories, any: true)) if categories.present? # Рекомендации аксессуаров
        result = result.group(:item_id).order('COUNT(item_id) DESC').limit(LIMIT_CF_ITEMS)
        ids = result.pluck(:item_id)

        # Рекомендации аксессуаров
        if categories.present? && ids.size < limit
          ids += items_to_recommend.in_categories(categories, any: true).where.not(id: ids+excluded_items_ids).limit(LIMIT_CF_ITEMS - ids.size).pluck(:id)
        end

        sr_weight(ids)
      end

      # @return Int[]
      def rescore(i_w, cf_weighted)
        i_w.merge(cf_weighted) do |key, sr, cf|
          # подмешиваем оценку SR
          (K_SR*sr.to_f + K_CF*cf.to_f)/(K_CF+K_SR)
        end
      end

      def items_which_cart_to_analyze
        [item.id]
      end
    end
  end
end
