class PushService
  class << self
    def extract_parameters(params)
      parameters = {}

      raise PushEventError.new('Session ID not provided') if params[:ssid].blank?
      raise PushEventError.new('Shop ID not provided') if params[:shop_id].blank?
      raise PushEventError.new('Action not provided') if params[:action].blank?
      raise PushEventError.new('Unknow action') unless Action::EVENT_TYPES.include?(params[:action])

      parameters
    end
  end
end
