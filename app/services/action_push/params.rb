module ActionPush
  class Params
    attr_accessor :raw

    attr_accessor :shop, :user, :action, :rating, :recommended_by,
                  :items, :user_uniqid, :order_id, :date

    def self.extract(params)
      new(params).extract
    end

    def initialize(params)
      @raw = params
    end

    def extract
      check
      extract_shop
      extract_static_attributes
      extract_user
      normalize_item_arrays
      extract_items
      self
    end

    def check
      raise ArgumentError.new('Session ID not provided') if raw[:ssid].blank?
      raise ArgumentError.new('Shop ID not provided') if raw[:shop_id].blank?
      raise ArgumentError.new('Action not provided') if raw[:event].blank?
      raise ArgumentError.new('Unknown action') unless Action::TYPES.include?(raw[:event])
      raise ArgumentError.new('Incorrect rating') if raw[:rating].present? and !(1..5).include?(raw[:rating])
      raise ArgumentError.new('Unknown recommender') if raw[:recommended_by].present? and !Recommender::Base::TYPES.include?(raw[:recommended_by])
    end

    def extract_shop
      @shop = Shop.find_by!(uniqid: raw[:shop_id])
    rescue ActiveRecord::RecordNotFound => e
      raise ArgumentError.new("Shop not found: #{raw[:shop_id]}")
    end

    def extract_static_attributes
      @action         = raw[:event]
      @rating         = raw[:rating]
      @recommended_by = raw[:recommended_by]
      @order_id       = raw[:order_id]
    end

    def extract_user
      user_fetcher = UserFetcher.new \
                                     uniqid: raw[:user_id],
                                     shop_id: shop.id,
                                     ssid: raw[:ssid]
      @user = user_fetcher.fetch
    end

    def normalize_item_arrays
      [:item_id, :category, :price, :is_available, :amount].each do |key|
        unless raw[key].is_a?(Array)
          raw[key] = raw[key].to_a.map(&:last)
        end
      end
    end

    def extract_items
      @items = []

      raw[:item_id].each_with_index do |item_id, i|
        category = raw[:category][i].to_s
        price = raw[:price][i]
        is_available = raw[:is_available][i].present? ? raw[:is_available][i] : true
        amount = raw[:amount].present? ? raw[:amount][i] : 1

        item_object = OpenStruct.new(uniqid: item_id,
                                     category_uniqid: category,
                                     price: price,
                                     is_available: is_available,
                                     amount: amount)

        @items << Item.fetch(shop.id, item_object)
      end
    end
  end
end
