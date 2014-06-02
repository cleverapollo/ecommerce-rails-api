module Recommender
  class Weighted < Base
    def recommended_ids
      ms = MahoutService.new
      ms.open
      result = ms.item_based_weight(params.user.id,
                                    weight: items_to_weight,
                                    imit: params.limit)
      ms.close

      result
    end

    def items_to_weight
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end
  end
end