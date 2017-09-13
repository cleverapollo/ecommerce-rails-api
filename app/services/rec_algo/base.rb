##
# Базовые рекомендер. Все наследуется от него.
#
module RecAlgo
  class Base

    # Доступные модификации отраслевых алгоритмов
    RANDOM_LIMIT_MULTIPLY = 3

    # Массив реализаций рекомендеров
    TYPES = Dir.glob(Rails.root + 'app/services/rec_algo/impl/*').map{|a| a.split('/').last.split('.').first }

    # @return [RecAlgo::Params] params
    attr_accessor :params
    attr_accessor :strict_categories

    class << self
      # Получить класс рекомендера по названию
      def get_implementation_for(recommender_type)
        raise Recommendations::Error.new('Unsupported recommender type') unless TYPES.include?(recommender_type)

        recommender_implementation_class_name(recommender_type).constantize
      end

      def recommender_implementation_class_name(recommender_type)
        "RecAlgo::Impl::#{recommender_type.camelize}"
      end

    end

    # Методы-сокращалки
    [:shop, :item, :user, :categories, :locations, :brands, :cart_item_ids, :limit, :search_query, :discount, :exclude].each do |accessor|
      define_method accessor do
        params.public_send(accessor)
      end
    end

    # Точка входа
    def recommendations
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end

    # Проверка, валидны ли параметры для конкретного рекомендера
    def check_params!
      raise Recommendations::Error.new('Shop ID not provided') if params.shop.blank?
      raise Recommendations::Error.new('Blank user') if params.user.blank?
    end

    # @param [RecAlgo::Params] params
    def initialize(params)
      @params = params
      @strict_categories = false
      check_params!
    end

    # Исключает ID-товаров из рекомендаций:
    # - текущий товар, если есть
    # - то, что в корзине
    # - купленные пользователем
    # - переданные в параметре :exclude
    def excluded_items_ids
      [item.try(:id), cart_item_ids, item_ids_bought_or_carted, params.exclude_item_ids].flatten.uniq.compact
    end

    # Получает ID всех товаров в корзине юзера и в истории заказов (исключая переодические)
    def item_ids_bought_or_carted
      @item_ids_bought_or_carted ||= shop.item_ids_bought_or_carted_by(user)
    end

  end
end
