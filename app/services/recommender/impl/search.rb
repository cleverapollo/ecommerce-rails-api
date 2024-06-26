# Принцип работы следующий:
# 1. На каждый запрос рекомендаций сохраняем поисковый запрос.
# 2. Ищем, кто делал такой поисковый запрос.
# 3. Если находим, то смотрим, что они покупали в день этого поискового запроса и рекомендуем это. Если не покупали,
#    то смотрим то, что добавляли в корзину.
# 4. Если поисковые запросы не нашли или ничего не найдено по ним, то показываем interesting и popular.


module Recommender
  module Impl
    class Search < Recommender::Base

      # Возвращает идентификаторы рекомендованных товаров
      # @return Int[]
      def recommended_ids
        items_to_weight.pluck(:id).sample(params.limit)
      end

      # TODO: добавить поддержку отраслевых
      def items_to_recommend
        super
      end


      def items_to_weight
        if search_query.present?
          relation = items_to_recommend.where.not(id: excluded_items_ids)
          item_ids = []
          SearchQuery.where(query: search_query).where('date >= ?', 1.months.ago).order(date: :desc).limit(100).each do |query|
            item_ids << OrderItem.where(order_id: Order.where(user_id: query.user_id).where(date: query.date.beginning_of_day..query.date.end_of_day) ).pluck(:item_id).uniq
          end
          item_ids.flatten!
          return items_to_recommend.where.not(id: excluded_items_ids).where(id: item_ids).where('sales_rate is not null and sales_rate > 0').order(sales_rate: :desc)
        else
          return Item.limit 0
        end
      end


      def check_params!
        super
        raise Recommendations::Error.new('Empty search query') if !search_query.present?
      end


    end
  end
end
