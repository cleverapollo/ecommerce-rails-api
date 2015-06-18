module Recommender
  module Impl
    class Interesting < Recommender::UserBased

      include ItemInjector

      def categories_for_promo
        params.categories.try(:any?) ? params.categories : @categories_for_promo
      end

      def inject_promotions(result)
        result
        # Промо только в категориях товара выдачи
        # @categories_for_promo = Item.where(id:result).pluck(:categories).flatten.compact.uniq
        # super(result)
      end

      def recommended_ids
        result = super

        inject_items(result)
      end
    end
  end
end
