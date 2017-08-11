##
# Базовый тип поиска
#
module SearchEngine


  class Base

    # Массив реализаций
    TYPES = %w(instant_search)

    # @return [SearchEngine::Params] params
    attr_accessor :params, :elastic_client

    class << self
      # Получить класс по названию
      def get_implementation_for(search_type)
        raise SearchEngine::Error.new('Unsupported search type') unless TYPES.include?(search_type)

        search_engine_implementation_class_name(search_type).constantize
      end

      def search_engine_implementation_class_name(search_type)
        "SearchEngine::#{search_type.camelize}"
      end

    end

    # Методы-сокращалки
    [:shop, :user, :cart_item_ids, :limit, :search_query, :excluded_items_ids].each do |accessor|
      define_method accessor do
        params.public_send(accessor)
      end
    end

    # Точка входа
    def recommendations
      # Проверка, валидны ли параметры для конкретного рекомендера
      check_params!

      # Получить рекомендованные внутренние ID товаров
      ids = recommended_ids

      items_data = {}
      Slavery.on_slave do
        shop.items.where(id: ids).each do |item|
          items_data[item.id] =
              {
                  id: item.uniqid,
                  name: item.name,
                  url: item.url,
                  image_url: params.resize_image.nil? ? item.image_url : item.resized_image_by_dimension("#{params.resize_image}x#{params.resize_image}"),
                  price: item.price.to_s,
                  currency: shop.currency,
                  _id: item.id
              }
        end

        result = []

        # Сохраним оригинальный порядок
        ids.each do |id|
          result.push(items_data[id])
        end

      end

      result
    end

    # Проверка, валидны ли параметры для конкретного рекомендера
    def check_params!
      raise SearchEngine::Error.new('Blank user') if params.user.blank?
      raise SearchEngine::Error.new('Blank shop') if params.shop.blank?
      raise SearchEngine::Error.new('Blank search type') if params.type.blank?
      raise SearchEngine::Error.new('Blank limit') if params.limit.blank?
    end

    # Получить рекомендованные внутренние ID товаров
    def recommended_ids
      raise NotImplementedError.new('This should be implemented in specific search engine class')
    end

    # @param [Recommendations::Params] params
    def initialize(params)
      @params = params
      self.elastic_client = ElasticSearchConnector.get_connection
    end

    # Исключает ID-товаров из рекомендаций:
    # - текущий товар, если есть
    # - то, что в корзине
    # - купленные пользователем
    # - переданные в параметре :exclude
    def excluded_items_ids
      [cart_item_ids, params.exclude_item_ids].flatten.uniq.compact
    end

  end
end
