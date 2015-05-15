##
# Ранжирующий рекомендер. Ранжирование отключено из-за низкого КПД.
#
module Recommender
  class Weighted < Base

    def recommended_ids
      result = []

      i_w = items_to_weight

      # if i_w.any?
      #   ms = MahoutService.new
      #   ms.open
      #   result = ms.item_based_weight(params.user.id,
      #                                 weight: i_w,
      #                                 limit: params.limit)
      #   ms.close
      # end
      reorder_result(result, i_w)

    end


    def items_to_weight
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end

    def reorder_result(cf_result, items_weight)
      # need to implemented for reorder
      items_weight
    end
  end
end
