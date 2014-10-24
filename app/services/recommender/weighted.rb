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
      result = i_w.sample(limit)

      result
    end

    def items_to_weight
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end
  end
end