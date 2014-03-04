module Recommender
  class Weighted < ItemBased
    def recommended_ids
      MahoutService.item_based_weight(params.user.id,
                                      weight: items_to_weight,
                                      limit: params.limit)
    end

    def items_to_weight
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end
  end
end