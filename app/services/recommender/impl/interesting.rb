module Recommender
  module Impl
    class Interesting < Recommender::UserBased

      include ItemInjector

      # def categories_for_promo
      #   params.categories.try(:any?) ? params.categories : @categories_for_promo
      # end
      #
      # def inject_promotions(result)
      #   # Промо только в категориях товара выдачи
      #    @categories_for_promo = Item.where(id:result).pluck(:category_ids).flatten.compact.uniq
      #    super(result, true)
      # end

      def recommended_ids
        result = super
        inject_items(result)
      end

      def inject_promotions(result, expansion_only = false)
        result
      end


      # Для interesting применяем отраслевую фильрацию
      # @return ActiveRecord::Relation
      def items_to_recommend
        apply_industrial_filter super
      end

    end
  end
end
