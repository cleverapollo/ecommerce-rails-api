##
# Базовые рекомендер. Все наследуется от него.
#
module Recommender
  class Base
    # Массив реализаций рекомендеров
    TYPES = Dir.glob(Rails.root + 'app/services/recommender/impl/*').map{|a| a.split('/').last.split('.').first }

    attr_accessor :params

    class << self
      # Получить класс рекомендера по названи.
      def get_implementation_for(recommender_type)
        raise Recommendations::Error.new('Unsupported recommender type') unless TYPES.include?(recommender_type)

        recommender_implementation_class_name(recommender_type).constantize
      end

      def recommender_implementation_class_name(recommender_type)
        "Recommender::Impl::#{recommender_type.camelize}"
      end
    end

    # Методы-сокращалки
    [:shop, :item, :user, :categories, :locations, :cart_item_ids, :limit].each do |accessor|
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

      # Для расширенного режима возвращаем аттрибуты товаров
      if params.try(:extended)
        result = shop.items.where(id: ids).map do |item|
          {
            id: item.uniqid,
            name: item.name,
            url: item.url,
            image_url: item.image_url,
            price: item.price.to_s
          }
        end
      else
        # Для обычного - переводим во внешние ID
        result = translate_to_external_ids(ids)
      end

      # Запоминаем, что магазин вызвал рекомендер
      params.shop.report_recommender(params.type.to_sym)

      return result
    end

    # Проверка, валидны ли параметры для конкретного рекомендера
    def check_params!
      raise Recommendations::Error.new('Blank user') if params.user.blank?
    end

    # Получить рекомендованные внутренние ID товаров
    def recommended_ids
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end

    def initialize(params)
      @params = params
    end

    # Перевести во внешние ID, сохраняя сортировку
    def translate_to_external_ids(array_of_internal_ids)
      array_of_items = Item.where(shop_id: params.shop.id).where(id: array_of_internal_ids).select([:id, :uniqid])
      array_of_internal_ids.map{|i_id| array_of_items.select{|i| i.id == i_id}.try(:first).try(:uniqid) }.compact
    end

    # Возвращает массив идентификаторов товаров, среди которых стоит рассчитывать рекомендации
    # @return Item[]
    def items_in_shop
      # Получаем все товары, которые можно рекомендовать, с учетом локаций, если локации указаны.
      relation = shop.items.recommendable.in_locations(locations)

      # Оставляем только те, которые содержат полные данные о товаре
      # для отображения карточки на клиенте без дополнительных запросов к БД
      relation = relation.widgetable if recommend_only_widgetable?

      # Фильтрация по кастомным атрибутам, если был запрос на это
      relation = relation.by_ca(params.custom_attributes_filter) if params.custom_attributes_filter.present?

      relation
    end

    # Исключает ID-товаров из рекомендаций:
    # - текущий товар, если есть
    # - то, что в корзине
    # - купленные пользователем
    # - переданные в параметре :exclude
    def excluded_items_ids
      [item.try(:id), cart_item_ids, shop.item_ids_bought_or_carted_by(user), shop.items.where(uniqid: params.exclude).pluck(:id)].flatten.uniq.compact
    end

    def recommend_only_widgetable?
      params.recommend_only_widgetable
    end

    # Добить выдачу рекомендаций рандомом
    def inject_random_items(given_ids)
      return given_ids if given_ids.size >= limit

      additional_ids = items_in_shop.where.not(id: (given_ids + excluded_items_ids)).order('RANDOM()').limit(limit - given_ids.count)

      given_ids + additional_ids.pluck(:id)
    end

    # Товары, доступные к рекомендациям - переопределяется в реализациях
    def items_to_recommend
      items_in_shop
    end
  end
end
