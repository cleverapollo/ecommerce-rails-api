class PopulateHelper
  class << self
    def create_action(shop, user, item, is_buy = false)
      a = item.actions.new(user: user,
                           shop: shop,
                           timestamp: 1.day.ago.to_i,
                           rating: Actions::View::RATING)

      if is_buy
        a.purchase_count = 1
        a.rating = Actions::Purchase::RATING
      end
      a.save

      MahoutAction.create(user:user, shop:shop, item:item)
    end

    def clear_model(model)
      model.delete_all
      model.reset_primary_key
      model.reset_sequence_name
      model.connection.reset_pk_sequence!(model.table_name)
    end

    def clear_all
      clear_model(Item)
      clear_model(User)
      clear_model(MahoutAction)
      clear_model(Action)
      clear_model(Shop)
    end
  end
end