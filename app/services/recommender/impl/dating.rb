module Recommender
  module Impl
    class Dating < Recommender::UserBased

      # Если указан массив объектов, среди которых проводить рекомендации, то считаем по ним.
      # Иначе рассчитываем по всей базе.
      # @return Item[]
      def items_to_recommend
        if params.items.present?
          shop.items.where(id: params.items)
        else
          super
        end
      end


      ##
      # Рассчитывает рекомендации.
      # Просто чистая коллаборативная фильтрация из базового класса.
      # Ранжирует тех, кто params[:items]. Исключает тех, кто пришел в params[:exclude]
      # @return Integer[]
      def recommended_ids
        super
      end

    end
  end
end
