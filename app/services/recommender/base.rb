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

    [:shop, :item, :user, :categories, :locations, :cart_item_ids].each do |accessor|
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
      raise ArgumentError.new('Blank user') if params.user.blank?
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
      i = params.shop.items.available
      i = i.where(locations_clause) if params.locations.present? && params.locations.any?
      i.pluck(:id)
    end

    def bought_or_carted_by_user
      params.user.actions.where('rating >= ?', '4.2').where(shop: params.shop, repeatable: false).pluck(:item_id)
    end

    class << self
      def exclude_in_recommendations(user_id, shop_id)
        Action.where(user_id: user_id).where('rating >= ?', 4.2).where(shop_id: shop_id, repeatable: false).pluck(:item_id)
      end
    end

    def locations_query
      if params.locations.present? && params.locations.any?
        "AND #{locations_clause}"
      end
    end

    def locations_clause
      "(array[#{params.locations.map{|l| "'#{l}'" }.join(',')}]::VARCHAR[] <@ locations)"
    end

    def item_query
      if params.item.present?
        "AND item_id != #{params.item.id}"
      end
    end

    def excluded_items_ids
      [item.try(:id), cart_item_ids, shop.item_ids_purchased_by(user)].flatten.uniq.compact
    end
  end
end
