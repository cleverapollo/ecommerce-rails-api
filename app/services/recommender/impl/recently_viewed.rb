module Recommender
  module Impl
    ##
    # Класс, реализующий рекомендации по алгоритму "Вы недавно смотрели"
    #
    class RecentlyViewed < Recommender::Base
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
        #ap params.recommend_only_widgetable
        #ap items_in_shop.to_sql
        #ap items_in_shop.where(id:relation.order('view_date DESC')).limit(limit).to_sql#.pluck(:id)
        items_in_shop.where(id: relation.order('view_date DESC').select(:item_id) ).limit(limit).pluck(:id)
      end
    end
  end
end
