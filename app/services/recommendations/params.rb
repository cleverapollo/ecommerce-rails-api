module Recommendations
  class Params
    attr_accessor :user
    attr_accessor :shop
    attr_accessor :type

    class << self
      def extract(params)
        extracted_params = new

        raise Recommendations::Error.new('Session ID not provided') if params[:ssid].blank?
        raise Recommendations::Error.new('Shop ID not provided') if params[:shop_id].blank?
        raise Recommendations::Error.new('Recommender type not provided') if params[:recommender_type].blank?

        extracted_params.shop = Shop.find_by!(uniqid: params[:shop_id])
        extracted_params.user = UserFetcher.new(uniqid: params[:user_id], ssid: params[:ssid], shop_id: extracted_params.shop.id).fetch
        extracted_params.type = params[:recommender_type]

        extracted_params
      end
    end
  end
end
