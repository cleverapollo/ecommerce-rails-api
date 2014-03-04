module Recommender
  class Filtered < ItemBased
    def recommended_ids
      MahoutService.item_based_filter(params.user.id,
                                      filter: items_to_filter,
                                      include: items_in_shop,
                                      exclude: bought_or_carted_by_user,
                                      limit: params.limit)
    end

    def items_to_filter
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end
  end
end
