#{"event"=>"view", "shop_id"=>"1234567890", "ssid"=>"12345", "item_id"=>["39559", "15464"], "price"=>["14375", "25000"], "is_available"=>["1", "0"], "category"=>["191", "15"], "action"=>"push", "controller"=>"events"}

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

        parameters.session = Session.find_by!(uniqid: params[:ssid])
        parameters.user = parameters.session.user
        parameters.shop = Shop.find_by!(uniqid: params[:shop_id])
        parameters.action = params[:event]
        parameters.rating = params[:rating]
        parameters.recommended_by = params[:recommended_by]
        parameters.items = []

        params[:item_id].each_with_index do |item_id, i|
          parameters.items << OpenStruct.new({
            item_id: item_id,
            category_id: params[:category][i],
            price: params[:price][i],
            is_available: params[:is_available][i],
            recommended_by: params[:recommended_by]
          })
        end

        parameters
      end
    end
  end
end
