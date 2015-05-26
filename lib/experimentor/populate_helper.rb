module Experimentor
  module PopulateHelper

    # Методы-сокращалки
    [:shop, :item, :user].each do |accessor|
      define_method accessor do
        @populate_data[accessor]
      end
    end

    def create(what, params={})
      @populate_data||={}
      @populate_data[what]||=[]
      @populate_data[what].push(FactoryGirl.create(what,params))
      @populate_data[what].last
    end

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

      MahoutAction.create(user: user, shop: shop, item: item)
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
