module Recommender
  class Base
    TYPES = Dir.glob(Rails.root + 'app/services/recommender/impl/*').map{|a| a.split('/').last.split('.').first }

    attr_accessor :params

    class << self
      def get_implementation_for(recommender_type)
        raise ArgumentError.new('Unsupported recommender type') unless TYPES.include?(recommender_type)

        recommender_implementation_class_name(recommender_type).constantize
      end

      def recommender_implementation_class_name(recommender_type)
        "Recommender::Impl::#{recommender_type.camelize}"
      end
    end

    def recommendations
      if check_params == false
        return []
      end

      ids = recommended_ids
      result = translate_to_external_ids(ids)
      report
      return result
    end

    def report
      if params.shop.connected_recommenders[params.type.to_sym] == false
        params.shop.connected_recommenders[params.type.to_sym] = true
        params.shop.save
      end
    end

    def check_params
      true
    end

    def recommended_ids
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end

    def initialize(params)
      @params = params
    end

    def translate_to_external_ids(array_of_internal_ids)
      Item.where(id: array_of_internal_ids, shop_id: params.shop.id).pluck(:uniqid)
    end

    def items_in_shop
      params.shop.items.available.pluck(:id)
    end

    def bought_or_carted_by_user
      params.user.actions.where('rating > ?', '4.2').where(shop: params.shop).pluck(:item_id)
    end
  end
end
