module Recommendations
  class Params
    attr_accessor :user
    attr_accessor :shop
    attr_accessor :type
    attr_accessor :categories
    attr_accessor :category_uniqid
    attr_accessor :item
    attr_accessor :item_id
    attr_accessor :cart_item_ids
    attr_accessor :limit
    attr_accessor :locations
    attr_accessor :items

    def initialize
      @cart_item_ids = []
    end

    class << self
      def extract(params)
        extracted_params = new
        extracted_params.categories = []
        extracted_params.locations = []

        raise ArgumentError.new('Session ID not provided') if params[:ssid].blank?
        raise ArgumentError.new('Shop ID not provided') if params[:shop_id].blank?
        raise ArgumentError.new('Recommender type not provided') if params[:recommender_type].blank?

        extracted_params.shop = Shop.find_by(uniqid: params[:shop_id])
        raise ArgumentError.new("Shop not found: #{params[:shop_id]}") if extracted_params.shop.blank?

        extracted_params.user = UserFetcher.new(uniqid: params[:user_id], ssid: params[:ssid], shop_id: extracted_params.shop.id).fetch
        extracted_params.type = params[:recommender_type]

        if params[:category].present?
          extracted_params.category_uniqid = params[:category].to_i.to_s
          extracted_params.categories << params[:category].to_i.to_s
        end

        extracted_params.limit = params[:limit].present? ? params[:limit].to_i : 10

        raise ArgumentError.new('Item should not be array') if params[:item_id].is_a?(Hash)

        if params[:item_id].present?
          extracted_params.item = Item.find_by(uniqid: params[:item_id].to_s, shop_id: extracted_params.shop.id)
          extracted_params.item_id = extracted_params.item.try(:id)
        end

        if params[:items].present?
          extracted_params.items = params[:items].split(',')
        end

        if params[:categories].present?
          extracted_params.categories += params[:categories].split(',')
        end

        if params[:locations].present?
          extracted_params.locations += params[:locations].split(',')
        end

        [:cart_item_id].each do |key|
          unless params[key].is_a?(Array)
            params[key] = params[key].to_a.map(&:last)
          end
        end

        params[:cart_item_id].each do |i|
          if item = Item.find_by(uniqid: i.to_s, shop_id: extracted_params.shop.id)
            extracted_params.cart_item_ids << item.id
          end
        end

        if extracted_params.item.blank? and extracted_params.cart_item_ids.any?
          extracted_params.item = Item.find_by(id: extracted_params.cart_item_ids.first)
        end

        extracted_params
      end
    end
  end
end
