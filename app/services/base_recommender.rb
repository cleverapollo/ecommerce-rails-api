module Recommenders
  class BaseRecommender
    TYPES = Dir.glob(Rails.root + 'services/recommenders/*').map{|a| a.split('/').last.split('.').first }

    class << self
      def get_implementation_for(recommender_type)
        raise ArgumentError.new('Unsupported recommender type') unless TYPES.include?(recommender_type)

        recommender_implementation_class_name(recommender_type).constantize
      end

      def recommender_implementation_class_name(recommender_type)
        "Recommenders::#{recommender_type.camelize}"
      end
    end
  end
end
