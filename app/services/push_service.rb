class PushService
  class << self
    def extract_parameters(params)
      parameters = OpenStruct.new

      raise PushEventError.new('Session ID not provided') if params[:ssid].blank?
      raise PushEventError.new('Shop ID not provided') if params[:shop_id].blank?
      raise PushEventError.new('Action not provided') if params[:action].blank?
      raise PushEventError.new('Unknown action') unless Action::EVENT_TYPES.include?(params[:action])
      raise PushEventError.new('Incorrect rating') if params[:rating].present? and !(1..5).include?(params[:rating])

      parameters.session = Session.find_by!(uniqid: params[:ssid])
      parameters.user = parameters.session.user
      parameters.shop = Shop.find_by!(uniqid: params[:shop_id])
      parameters.action = params[:action]
      parameters.rating = params[:rating]

      parameters
    end
  end
end
