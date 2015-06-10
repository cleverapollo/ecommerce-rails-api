module Recommender
  module Impl
    ##
    # Класс, реализующий рекомендации по алгоритму "Вы недавно смотрели"
    #
    class RecentlyViewed < Recommender::Raw
      # Суть крайне проста - найти N последних просмотренных пользователем товаров

      # Исключает ID-товаров из рекомендаций:
      # - текущий товар, если есть
      # - переданные в параметре :exclude
      def excluded_items_ids
        [item.try(:id), shop.items.where(uniqid: params.exclude).pluck(:id)].flatten.uniq.compact
      end

      def recommended_ids
        relation = shop.actions.where(user: user).where('view_count > 0')
        relation = relation.where.not(item_id: excluded_items_ids)
        relation.order('view_date DESC').limit(limit).pluck(:item_id)
      end
    end
  end
end
