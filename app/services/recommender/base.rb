##
# Базовые рекомендер. Все наследуется от него.
#
module Recommender
  class Base

    # Доступные модификации отраслевых алгоритмов
    RANDOM_LIMIT_MULTIPLY = 3

    # Массив реализаций рекомендеров
    TYPES = Dir.glob(Rails.root + 'app/services/recommender/impl/*').map{|a| a.split('/').last.split('.').first }

    attr_accessor :params, :strict_categories

    class << self
      # Получить класс рекомендера по названию
      def get_implementation_for(recommender_type)
        raise Recommendations::Error.new('Unsupported recommender type') unless TYPES.include?(recommender_type)

        recommender_implementation_class_name(recommender_type).constantize
      end

      def recommender_implementation_class_name(recommender_type)
        "Recommender::Impl::#{recommender_type.camelize}"
      end

    end

    # Методы-сокращалки
    [:shop, :item, :user, :categories, :locations, :brands, :cart_item_ids, :limit, :search_query, :discount].each do |accessor|
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

      if params.try(:extended)
        items_data = {}
        shop.items.where(id: ids).each do |item|
          items_data[item.id] =
              {
                  id: item.uniqid,
                  name: item.name,
                  url: item.url,
                  image_url: item.image_url,
                  price: item.price.to_s
              }
        end

        result = []
        # Сохраним оригинальный порядок
        ids.each do |id|
          result.push(items_data[id])
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
      @strict_categories = false
    end

    # Перевести во внешние ID, сохраняя сортировку
    # @return Int[]
    def translate_to_external_ids(array_of_internal_ids)
      result = []
      # Эта проверка экономит 2ms на запросы к БД, когда результирующий массив пустой и ActiveRecord делает запросы в SQL типа "where 0=1"
      if array_of_internal_ids.length > 0
        array_of_items = Item.where(shop_id: params.shop.id).where(id: array_of_internal_ids).select([:id, :uniqid])
        return array_of_internal_ids.map{|i_id| array_of_items.select{|i| i.id == i_id}.try(:first).try(:uniqid) }.compact
      end
      result
    end

    # Возвращает массив идентификаторов товаров, среди которых стоит рассчитывать рекомендации
    # @return Item[]
    def items_in_shop
      # Получаем все товары, которые можно рекомендовать, с учетом локаций, если локации указаны.
      relation = shop.items.recommendable.in_locations(locations)

      # Получаем акционные товары, если был запрос на акции
      relation = relation.discount if discount == true


      # Оставляем только те, которые содержат полные данные о товаре
      # для отображения карточки на клиенте без дополнительных запросов к БД
      relation = relation.widgetable if recommend_only_widgetable?
      relation = relation.by_brands(brands)

      relation
    end


    # Применить отраслевую фильтрацию к товарной выборке
    # @param relation [ActiveRecord::Relation]
    # @return ActiveRecord::Relation
    def apply_industrial_filter(relation)

      # Если известен пол покупателя и у магазина включен решим отраслевого
      if shop.subscription_plans.product_recommendations.paid.exists?

        # Фильтрация по полу
        if user.try(:gender).present?
          # Пропускаем товары с противоположным полом, но не детские. Но если товаров совсем не найдено, то не применять фильтр
          # Сброс не работает, т.к. дополнительные фильтры отдельных рекомендеров (например, популярные в категориях) еще не применены.
          # if relation.where("is_child IS TRUE OR ( (fashion_gender = ? OR fashion_gender IS NULL) AND (cosmetic_gender = ? OR cosmetic_gender IS NULL) )", user.gender, user.gender ).exists?
          relation = relation.where("is_child IS TRUE OR ( (fashion_gender = ? OR fashion_gender IS NULL) AND (cosmetic_gender = ? OR cosmetic_gender IS NULL) )", user.gender, user.gender )
          # end
        end

        # Фильтрация по маркам авто
        if user.try(:compatibility).present?
          relation = relation.where("
              (is_auto = true AND (auto_compatibility->'brands' ?| ARRAY[:brand] #{user.compatibility['model'].present? ? "OR auto_compatibility->'models' ?| ARRAY[:model]" : ''}))
              OR
              (is_auto = true AND auto_compatibility IS NULL)
              OR is_auto IS NULL
          ", brand: user.compatibility['brand'], model: user.compatibility['model'])
        end

        # Фильтрация по VIN авто
        if user.try(:vds).present?
          relation = relation.where('(is_auto = true AND auto_vds @> ARRAY[?]) OR (is_auto = true AND auto_vds IS NULL) OR is_auto IS NULL', user.vds)
        end

      end

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

      relation = items_to_recommend
      if categories.present?
        relation = relation.in_categories(categories, any:true)
      end

      # Не использовать order RANDOM()
      additional_ids = relation.where.not(id: (given_ids + excluded_items_ids)).limit(RANDOM_LIMIT_MULTIPLY * limit).pluck(:id)


      given_ids + additional_ids.shuffle.sample(limit - given_ids.count)
    end

    # Товары, доступные к рекомендациям - переопределяется в реализациях
    def items_to_recommend
      items_in_shop
    end
  end
end
