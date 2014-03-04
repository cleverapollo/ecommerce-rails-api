module Recommendations
  class Params
    attr_accessor :user
    attr_accessor :shop
    attr_accessor :type
    attr_accessor :category_uniqid
    attr_accessor :item
    attr_accessor :item_id
    attr_accessor :cart_item_ids
    attr_accessor :limit

    def initialize
      @cart_item_ids = []
    end

    class << self
      def extract(params)
        extracted_params = new

        raise Recommendations::Error.new('Session ID not provided') if params[:ssid].blank?
        raise Recommendations::Error.new('Shop ID not provided') if params[:shop_id].blank?
        raise Recommendations::Error.new('Recommender type not provided') if params[:recommender_type].blank?

        extracted_params.shop = Shop.find_by!(uniqid: params[:shop_id])
        extracted_params.user = UserFetcher.new(uniqid: params[:user_id], ssid: params[:ssid], shop_id: extracted_params.shop.id).fetch
        extracted_params.type = params[:recommender_type]
        extracted_params.category_uniqid = params[:category].present? ? params[:category].to_i.to_s : nil
        extracted_params.limit = params[:limit].present? ? params[:limit].to_i : 10

        if params[:item_id].present?
          extracted_params.item = Item.find_by(uniqid: params[:item_id])
          extracted_params.item_id = extracted_params.item.try(:id)
        end

        [:cart_item_id].each do |key|
          unless params[key].is_a?(Array)
            params[key] = params[key].to_a.map(&:last)
          end
        end

        params[:cart_item_id].each do |i|
          if item = Item.find_by(uniqid: i)
            extracted_params.cart_item_ids << item.id
          end
        end

        extracted_params
      end
    end
  end
end
