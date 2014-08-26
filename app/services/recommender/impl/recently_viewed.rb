module Recommender
  module Impl
    class RecentlyViewed < Recommender::Raw
      LIMIT = 10

      def recommended_ids
        relation = shop.actions.where(user: user).where('view_count > 0')
        relation = relation.where.not(item: item) if item.present?
        relation.order('view_date DESC').limit(LIMIT).pluck(:item_id)
      end
    end
  end
end
