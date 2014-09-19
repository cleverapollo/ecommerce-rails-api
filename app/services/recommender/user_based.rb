module Recommender
  class UserBased < Base
    def recommended_ids
      ms = MahoutService.new
      ms.open
      result = ms.user_based(params.user.id,
                             params.shop.id,
                             params.item_id,
                             #include: items_in_shop,
                             include: [],
                             exclude: shop.item_ids_bought_or_carted_by(user),
                             limit: params.limit)
      ms.close

      result
    end
  end
end
