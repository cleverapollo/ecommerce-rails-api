module ActionPush
  class ParamsExtractor
    class << self
      def extract(params)
        parameters = OpenStruct.new

        raise PushEventError.new('Session ID not provided') if params[:ssid].blank?
        raise PushEventError.new('Shop ID not provided') if params[:shop_id].blank?
        raise PushEventError.new('Action not provided') if params[:event].blank?
        raise PushEventError.new('Unknown action') unless Action::TYPES.include?(params[:event])
        raise PushEventError.new('Incorrect rating') if params[:rating].present? and !(1..5).include?(params[:rating])

        parameters.ssid = params[:ssid]
        parameters.shop = Shop.find_by!(uniqid: params[:shop_id])
        parameters.action = params[:event]
        parameters.rating = params[:rating]
        parameters.recommended_by = params[:recommended_by]
        parameters.items = []
        parameters.raw_items = []
        parameters.user_uniqid = params[:user_id]
        parameters.order_id = params[:order_id]
        parameters.user = UserFetcher.new(uniqid: parameters.user_uniqid, shop_id: parameters.shop.id, ssid: parameters.ssid).fetch

        params[:item_id].each_with_index do |item_id, i|
          item_object = OpenStruct.new(uniqid: item_id,
                                       category_uniqid: params[:category][i].to_i,
                                       price: params[:price][i],
                                       is_available: params[:is_available][i],
                                       amount: params[:amount].present? ? params[:amount][i] : 1
                                       )
          parameters.raw_items << item_object
          parameters.items << Item.fetch(parameters.shop.id, item_object)
        end

        parameters
      end
    end
  end
end
