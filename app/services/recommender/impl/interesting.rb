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

      def items_in_shop
        result = super
        if params.fashion?
          result = result.where('is_fashion IS TRUE')
          gender_algo = SectoralAlgorythms::VirtualProfile::Gender.new(params.user.profile)
          result = gender_algo.modify_relation_with_rollback(result)
        end
        if params.cosmetic?
          result = result.where('is_cosmetic IS TRUE')
        end
        result
      end

      def recommended_ids
        result = super

        inject_items(result)
      end
    end
  end
end
