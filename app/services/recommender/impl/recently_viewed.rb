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

        item_ids = relation.order('view_date DESC').limit(limit*5).pluck(:item_id)

        # Сохраняем сортировку
        available_ids = items_in_shop.where(id: item_ids).pluck(:id)
        result = item_ids - (item_ids - available_ids)

        item_ids.delete_if { |item_id| !result.include?(item_id)}
        item_ids.take(limit)
      end
    end
  end
end
