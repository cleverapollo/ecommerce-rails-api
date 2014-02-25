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
    end

    def fetch_action_for(item)
      a = concrete_action_class.find_or_initialize_by user_id: params.user.id, shop_id: params.shop.id, item_id: item.id
      a.timestamp = Date.current.to_time.to_i
      a
    end
  end
end
