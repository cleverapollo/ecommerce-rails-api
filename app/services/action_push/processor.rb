module ActionPush
  class Processor
    attr_reader :params
    attr_reader :concrete_action_class

    def initialize(params)
      @params = params
      @concrete_action_class = Action.get_implementation_for params.action
    end

    def process
      params.items.each do |item|
        action = fetch_action_for item
        action.process params
      end

      concrete_action_class.mass_process(params)

      report
    end

    def report
      if params.shop.connected_events[params.action.to_sym] != true
        params.shop.connected_events[params.action.to_sym] = true
        params.shop.save
      end
    end

    def fetch_action_for(item)
      a = concrete_action_class.find_or_initialize_by user_id: params.user.id, shop_id: params.shop.id, item_id: item.id
      a.assign_attributes \
                          category_uniqid: item.category_uniqid,
                          is_available: item.is_available,
                          price: item.price,
                          timestamp: (params.date || Date.current.to_time.to_i),
                          locations: item.locations,
                          brand: item.brand
      a
    end
  end
end
