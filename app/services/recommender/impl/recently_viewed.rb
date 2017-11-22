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
        # Достаем недавно просмотренные товары
        items = ActionCl.where(shop_id: shop.id, object_type: 'Item', event: 'view', session_id: params.session.id)
                    .in_date(1.month.ago..Time.current)
                    .order(date: :desc, created_at: :desc)
                    .limit(limit * 5)
                    .pluck(:object_id).uniq

        # Сохраняем сортировку
        available_ids = Hash[items_in_shop.where(uniqid: items).where.not(id: excluded_items_ids).pluck(:uniqid, :id)]
        result = []
        items.each do |item|
          result << available_ids[item] if available_ids[item].present?
        end

        result
      end
    end
  end
end
