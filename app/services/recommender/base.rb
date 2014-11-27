module Recommender
  class Base
    TYPES = Dir.glob(Rails.root + 'app/services/recommender/impl/*').map{|a| a.split('/').last.split('.').first }

    attr_accessor :params

    class << self
      def get_implementation_for(recommender_type)
        raise Recommendations::Error.new('Unsupported recommender type') unless TYPES.include?(recommender_type)

        recommender_implementation_class_name(recommender_type).constantize
      end

      def recommender_implementation_class_name(recommender_type)
        "Recommender::Impl::#{recommender_type.camelize}"
      end
    end

    [:shop, :item, :user, :categories, :locations, :cart_item_ids, :limit].each do |accessor|
      define_method accessor do
        params.public_send(accessor)
      end
    end

    def recommendations
      check_params!

      ids = recommended_ids
      result = translate_to_external_ids(ids)

      params.shop.report_recommender(params.type.to_sym)

      return result
    end

    def check_params!
      raise Recommendations::Error.new('Blank user') if params.user.blank?
    end

    def recommended_ids
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end

    def initialize(params)
      @params = params
    end

    def translate_to_external_ids(array_of_internal_ids)
      array_of_items = Item.where(shop_id: params.shop.id).where(id: array_of_internal_ids).select([:id, :uniqid])
      array_of_internal_ids.map{|i_id| array_of_items.select{|i| i.id == i_id}.try(:first).try(:uniqid) }.compact
    end

    def items_in_shop
      shop.items.available.in_locations(locations).pluck(:id)
    end

    def excluded_items_ids
      [item.try(:id), cart_item_ids, shop.item_ids_bought_or_carted_by(user)].flatten.uniq.compact
    end

    def inject_random_items(given_ids)
      return given_ids if given_ids.size >= limit

      additional_ids = shop.items.available.in_locations(locations).where.not(id: given_ids && excluded_items_ids).order('RANDOM()').limit(limit - given_ids.count).pluck(:id)
      given_ids + additional_ids
    end
  end
end
