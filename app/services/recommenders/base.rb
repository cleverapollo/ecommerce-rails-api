module Recommenders
  class Base
    TYPES = (Dir.glob(Rails.root + 'app/services/recommenders/*').map{|a| a.split('/').last.split('.').first } - ['base'])

    attr_accessor :params

    class << self
      def get_implementation_for(recommender_type)
        raise ArgumentError.new('Unsupported recommender type') unless TYPES.include?(recommender_type)

        recommender_implementation_class_name(recommender_type).constantize
      end

      def recommender_implementation_class_name(recommender_type)
        "Recommenders::#{recommender_type.camelize}"
      end
    end

    def initialize(params)
      @params = params
    end

    def recommendations
      est = items_to_estimate
      r = if est.any?
        MahoutService.recommendations(self.params.user.id,
                                          items_to_include: [],
                                          items_to_exclude: [],
                                          items_to_estimate: est,
                                          limit: 10)
      else
        MahoutService.recommendations(self.params.user.id,
                                          items_to_include: items_to_include,
                                          items_to_exclude: items_to_exclude,
                                          items_to_estimate: [],
                                          limit: 10)
      end

      translate_to_external_ids(r, params.shop)
    end

    def items_to_include
      params.shop.available_item_ids
    end

    def items_to_exclude
      params.user.items_ids_bought_in_shop(params.shop)
    end

    def items_to_estimate
      []
    end

    def translate_to_external_ids(a, shop)
      Item.where(id: a, shop_id: shop.id).pluck(:uniqid)
    end
  end
end
