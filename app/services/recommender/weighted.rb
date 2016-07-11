##
# Ранжирующий рекомендер. Ранжирование отключено из-за низкого КПД.
#
module Recommender
  class Weighted < Base

    include ItemInjector

    # @return Int[]
    def recommended_ids
      result = []

      i_w = items_to_weight

      result = if result.size > limit
        i_w.sample(limit)
      else
        i_w
      end

      inject_items(result, strict_categories = false)
    end

    def items_to_weight
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end
  end
end
