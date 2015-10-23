module Recommender
  module Impl
    class Supply < Recommender::Personalized

      K_SR = 1.0
      K_CF = 1.0


      def items_to_recommend
        raise Recommendations::IncorrectParams.new('Need sectoral algorythms for this recommender') unless params.modification.present?

        # Дополнительные отраслевые модификации не требуются
        super
      end

      def items_to_weight

        supply_ids = []


        # найдем товары, которые пора бы прикупить
        supply_ids = Item.widgetable.recommendable.where(id: SectoralAlgorythms::VirtualProfile::Periodicly.new(params.user.profile).items_need_to_buy)

        return [] if supply_ids.none?

        result = OrderItem.where('order_id IN (SELECT DISTINCT(order_id) FROM order_items WHERE item_id IN (?) limit 100)', supply_ids)
        result = result.where.not(item_id: excluded_items_ids)
        result = result.joins(:item).merge(items_to_recommend) # Эта конструкция подгружает фильтрацию relation для того, чтобы оставить только те товары, которые можно рекомендовать. То есть item_to_recommend тут не добавляет массив товаров
        result = result.where(item_id: Item.in_categories(categories, any: true)) if categories.present? # Рекомендации аксессуаров
        result = result.group(:item_id).order('COUNT(item_id) DESC').limit(LIMIT_CF_ITEMS)
        ids = result.pluck(:item_id)

        sr_weight(ids)
      end

      # @return Int[]
      def rescore(i_w, cf_weighted)
        i_w.merge(cf_weighted) do |key, sr, cf|
          # подмешиваем оценку SR
          (K_SR * sr.to_f + K_CF * cf.to_f)/(K_CF + K_SR)
        end

      end

      def inject_promotions(result)
        result
        # Промо только в категориях товара выдачи
        # @categories_for_promo = Item.where(id:result).pluck(:categories).flatten.compact.uniq
        # super(result)
      end

      def inject_random_items(result)
        # Не включать рандомные итемы
        result
      end
    end
  end
end
