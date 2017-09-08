##
# Базовые рекомендер. Все наследуется от него.
# @deprecated
module Recommender
  # @deprecated
  class Base

    # Доступные модификации отраслевых алгоритмов
    RANDOM_LIMIT_MULTIPLY = 3

    # Массив реализаций рекомендеров
    TYPES = Dir.glob(Rails.root + 'app/services/recommender/impl/*').map{|a| a.split('/').last.split('.').first }

    # @return [Recommendations::Params] params
    attr_accessor :params
    attr_accessor :strict_categories

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
    [:shop, :item, :user, :categories, :locations, :brands, :cart_item_ids, :limit, :search_query, :discount, :exclude].each do |accessor|
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
      params.shop.report_recommender(params.type.to_sym) if params.track_recommender

      # Дополнительно указываем запрос рекоммендера популярного в категории
      if params.type == 'popular' && params.categories.present? && params.categories.any?
        params.shop.report_recommender(:popular_category)
      end

      result
    end

    # Проверка, валидны ли параметры для конкретного рекомендера
    def check_params!
      raise Recommendations::Error.new('Blank user') if params.user.blank?
    end

    # Получить рекомендованные внутренние ID товаров
    def recommended_ids
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end

    # @param [Recommendations::Params] params
    def initialize(params)
      @params = params
      @strict_categories = false
    end

    # Перевести во внешние ID, сохраняя сортировку
    # @return Int[]
    def translate_to_external_ids(array_of_internal_ids)
      result = []
      Slavery.on_slave do
        # Эта проверка экономит 2ms на запросы к БД, когда результирующий массив пустой и ActiveRecord делает запросы в SQL типа "where 0=1"
        if array_of_internal_ids.length > 0
          array_of_items = Item.where(shop_id: params.shop.id).where(id: array_of_internal_ids).select([:id, :uniqid])
          return array_of_internal_ids.map{|i_id| array_of_items.select{|i| i.id == i_id}.try(:first).try(:uniqid) }.compact
        end
      end
      result
    end

    # Возвращает массив идентификаторов товаров, среди которых стоит рассчитывать рекомендации
    # @return Item[]
    def items_in_shop
      # Получаем все товары, которые можно рекомендовать, с учетом локаций, если локации указаны и сезонностью
      relation = shop.items.recommendable.in_locations(locations).in_seasonality

      # Получаем акционные товары, если был запрос на акции
      relation = relation.discount if discount == true


      # Оставляем только те, которые содержат полные данные о товаре
      # для отображения карточки на клиенте без дополнительных запросов к БД
      relation = relation.widgetable if recommend_only_widgetable?
      relation = relation.by_brands(brands)

      relation
    end


    # Применяет ювелирный отраслевой фильтр (общий)
    # @return ActiveRecord::Relation
    def apply_jewelry_industrial_filter(relation)

      if shop.has_products_jewelry? && user.try(:jewelry).present? && user.jewelry.is_a?(Hash) && user.jewelry.keys.any?

        # Физические характеристики по ИЛИ
        materials = []
        materials << " (jewelry_metal IS NOT NULL AND jewelry_metal = $$#{user.jewelry['metal']}$$) " if user.jewelry['metal'].present?
        materials << " (jewelry_color IS NOT NULL AND jewelry_color = $$#{user.jewelry['color']}$$) " if user.jewelry['color'].present?
        materials << " (jewelry_gem IS NOT NULL AND jewelry_gem = $$#{user.jewelry['gem']}$$) " if user.jewelry['gem'].present?

        # Размеры
        sizes = []
        sizes << " (ring_sizes IS NOT NULL AND ring_sizes ? $$#{user.jewelry['ring_size']}$$::varchar) " if user.jewelry['ring_size'].present?
        sizes << " (bracelet_sizes IS NOT NULL AND bracelet_sizes ? $$#{user.jewelry['bracelet_size']}$$::varchar) " if user.jewelry['bracelet_size'].present?
        sizes << " (chain_sizes IS NOT NULL AND chain_sizes ? $$#{user.jewelry['chain_size']}$$::varchar) " if user.jewelry['chain_size'].present?

        # Группируем фильтры
        filters = []
        filters << " ( #{materials.join(' OR ')} ) " if materials.any?
        filters << " ( #{sizes.join(' OR ')} ) " if sizes.any?
        filters << " ( jewelry_gender IS NULL OR jewelry_gender = $$#{user.jewelry['gender']}$$ ) " if user.jewelry['gender'].present?

        relation = relation.where("is_jewelry IS NULL OR (is_jewelry IS TRUE AND #{filters.join(' AND ')} )" )
      end

      relation

    end

    # Применить отраслевую фильтрацию к товарной выборке
    # @param relation [ActiveRecord::Relation]
    # @return ActiveRecord::Relation
    def apply_industrial_filter(relation)

      # Фильтрация по полу
      if user.try(:gender).present? && (shop.has_products_fashion? || shop.has_products_kids? || shop.has_products_cosmetic?)
        # Пропускаем товары с противоположным полом, но не детские. Но если товаров совсем не найдено, то не применять фильтр
        relation = relation.where("is_child IS TRUE OR ( (fashion_gender = ? OR fashion_gender IS NULL) AND (cosmetic_gender = ? OR cosmetic_gender IS NULL) )", user.gender, user.gender )
      end

      # Фильтрация по размеру взрослой одежды
      if user.try(:gender).present? && user.fashion_sizes.is_a?(Hash) && user.fashion_sizes.keys.any?
        conditions = []
        conditions << '(is_fashion IS NOT TRUE OR fashion_gender IS NULL OR fashion_wear_type IS NULL)'
        user.fashion_sizes.each do |type, sizes|
          conditions << "(is_fashion IS TRUE AND fashion_gender = '#{user.gender}' AND fashion_wear_type = '#{type}' AND fashion_sizes && ARRAY['#{sizes.join("','")}']::varchar[])"
        end
        # TODO Не забыть добавить условие про детские товары, что к ним не применяются эти ограничения
        if conditions.count > 1
          relation = relation.where(conditions.join(' OR '))
        end
      end

      if shop.has_products_auto?

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

      # Фильтрация по животным.
      if shop.has_products_pets? && user.try(:pets).present? && user.pets.is_a?(Array) && user.pets.any?
        subconditions = user.pets.map do |pet|
          if pet['type'] && pet['breed']
            " OR (is_pets IS TRUE AND pets_type = $$#{pet['type']}$$ AND pets_breed = $$#{pet['breed']}$$)"
          elsif pet['type']
            " OR (is_pets IS TRUE AND pets_type = $$#{pet['type']}$$ AND pets_breed IS NULL)"
          else
            nil
          end
        end.compact.join("")
        relation = relation.where("is_pets IS NULL OR (is_pets IS TRUE AND pets_type IS NULL) #{subconditions}")
      end

      # Фильтрация по ювелирке
      relation = apply_jewelry_industrial_filter relation

      # Фильтрация по детям
      # Оставляем:
      # - не детские товары
      # - детские товары без указания пола
      if shop.has_products_kids? && user.try(:children).present? && user.children.is_a?(Array) && user.children.any?
        subconditions = user.children.map do |kid|
          if kid.is_a?(Hash) && kid.keys.any?
          partial_subcondition = ' OR ( is_child IS TRUE '
          if kid['gender'].present?
            partial_subcondition += " AND (child_gender = '#{kid['gender']}' OR child_gender IS NULL) "
          end
          if kid['age_max'].present? && kid['age_min'].present?
            # Есть интервал возрастов
            # Терминология: N - нижняя граница, M - верхняя граница. Без 1 - ребенок. С 1 - товар.
            # (N ≥ N1 or N1 IS NULL) && (M ≤ M1 OR M1 IS NULL) - OK
            # (N ≥ N1 or N1 IS NULL) && (M ≥ M1 OR M1 IS NULL) - OK
            # (N ≤ N1 or N1 IS NULL) && (M ≤ M1 OR M1 IS NULL) - OK
            # (N ≤ N1 or N1 IS NULL) && (M ≥ M1 OR M1 IS NULL) - OK
            # N > M1 - BAD
            # M < N1 - BAD
            partial_subcondition += " AND (child_age_max >= '#{kid['age_min'].to_f}' OR child_age_max IS NULL) "
            partial_subcondition += " AND (child_age_min <= '#{kid['age_max'].to_f}' OR child_age_min IS NULL) "
          elsif kid['age_max'].present? && kid['age_min']
            # Какой-то из возрастов отсутствует, поэтому оперируем одним возрастом
            kid['age'] = kid['age_max'] || kid['age_min']
            partial_subcondition += " AND (child_age_max <= '#{kid['age'].to_f}' OR child_age_max IS NULL) "
            partial_subcondition += " AND (child_age_min >= '#{kid['age'].to_f}' OR child_age_min IS NULL) "
          end
          partial_subcondition + ' ) ' # Возвращаем это
          else
            nil
          end
        end.compact.join("")
        relation = relation.where("is_child IS NULL #{subconditions}")
      end

      relation

    end


    # Исключает ID-товаров из рекомендаций:
    # - текущий товар, если есть
    # - то, что в корзине
    # - купленные пользователем
    # - переданные в параметре :exclude
    def excluded_items_ids
      [item.try(:id), cart_item_ids, item_ids_bought_or_carted, params.exclude_item_ids].flatten.uniq.compact
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
      additional_ids = Slavery.on_slave { relation.where.not(id: (given_ids + excluded_items_ids)).limit(RANDOM_LIMIT_MULTIPLY * limit).pluck(:id) }


      given_ids + additional_ids.shuffle.sample(limit - given_ids.count)
    end

    # Товары, доступные к рекомендациям - переопределяется в реализациях
    def items_to_recommend
      items_in_shop
    end

    # Получает ID всех товаров в корзине юзера и в истории заказов (исключая переодические)
    def item_ids_bought_or_carted
      @item_ids_bought_or_carted ||= shop.item_ids_bought_or_carted_by(user)
    end
  end
end
