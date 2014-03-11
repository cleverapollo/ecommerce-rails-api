module Recommender
  class UserBased < Base
    def recommended_ids
      MahoutService.new.user_based(params.user.id,
                                   include: items_in_shop,
                                   exclude: bought_or_carted_by_user,
                                   limit: params.limit)
    end
  end
end
