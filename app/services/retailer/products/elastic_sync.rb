module Retailer
  module Products
    class ElasticSync

      attr_accessor :shop, :client

      # @param [Shop] shop
      def initialize(shop)
        if shop.class == Fixnum
          shop = Shop.find(shop)
        end
        self.shop = shop
        self.client = ElasticSearchConnector.get_connection
      end

      # @return Boolean
      def perform

        # Не забыть удалить неактивные товары
        # Делается примерно так: https://www.elastic.co/guide/en/elasticsearch/reference/5.5/docs-reindex.html
        # Создаем новый индекс
        # Удаляем алиас, направленный на старый индекс
        # Создаем алиас на новый индекс

        new_index_name = "shop-#{shop.id}-#{DateTime.current.strftime('%Y-%m-%d-%H-%M')}-#{rand(100)}"
        alias_name = "shop-#{shop.id}"

        # Создаем индексы с настройками mapping и типами данных
        client.indices.create index: new_index_name, body: index_structure

        # Массив действующих категорий
        active_category_ids = []

        # Массив идентификаторов товаров, чтобы потом удалить те, которые отсутствуют в этом списке
        # active_item_ids = []

        # Индексируем товары пачками по 2000 штук
        shop.items.recommendable.widgetable.find_in_batches(batch_size: 2000) do |items|

          bulk = []

          # Перебираем товары
          items.each do |item|

            # Пополняем список категорий для индексации
            active_category_ids += item.category_ids.flatten.compact if item.category_ids

            # Добавляем в массив активный товар
            # active_item_ids << item.id

            item_keywords = (item.name.to_s + ' ' + item.type_prefix.to_s + ' ' +  item.model.to_s + ' ' +  item.vendor_code.to_s).split("\s").delete_if{|x| x.length <= 2 }.uniq.compact

            # Добавляем товар для индексации
            bulk << { index: { _index: new_index_name, _type: 'product', _id: item.id } }
            bulk << {
                name:             item.name,
                suggest_product:  {
                    input: item_keywords << item.name,
                    contexts: {
                        widgetable: item.widgetable
                    }
                },
                description:      item.description,
                price:            item.price.to_f,
                oldprice:         item.oldprice.to_f,
                price_margin:     item.price_margin.to_f,
                category_ids:     item.category_ids,
                sales_rate:       item.sales_rate.to_f,
                brand:            item.brand,
                picture:          item.resized_image_by_dimension('180x180'),
                url:              item.url,
                uniqid:           item.uniqid,
                discount:         item.discount,
                seasonality:      item.seasonality,
                leftovers:        item.leftovers,

                type_prefix:      item.type_prefix,
                vendor_code:      item.vendor_code,
                model:            item.model,
                widgetable:       item.widgetable,
                location_ids:     item.location_ids.is_a?(Array) && item.location_ids.any? ? item.location_ids.map { |x| x.to_s } : ['global'],
                barcode:          item.barcode,

                is_fashion:       item.is_fashion,
                fashion_gender:   item.fashion_gender,
                fashion_wear_type: item.fashion_wear_type,
                fashion_feature:  item.fashion_feature,
                fashion_sizes:    item.fashion_sizes,

                is_child:         item.is_child,
                child_gender:     item.child_gender,
                child_type:       item.child_type,
                child_age_min:    item.child_age_min,
                child_age_max:    item.child_age_max,

                is_cosmetic:              item.is_cosmetic,
                cosmetic_gender:          item.cosmetic_gender,
                cosmetic_hypoallergenic:  item.cosmetic_hypoallergenic,
                cosmetic_skin_part:       item.cosmetic_skin_part,
                cosmetic_skin_type:       item.cosmetic_skin_type,
                cosmetic_skin_condition:  item.cosmetic_skin_condition,
                cosmetic_hair_type:       item.cosmetic_hair_type,
                cosmetic_hair_condition:  item.cosmetic_hair_condition,
                cosmetic_volume:          item.cosmetic_volume,
                cosmetic_periodic:        item.cosmetic_periodic,
                cosmetic_nail:            item.cosmetic_nail,
                cosmetic_nail_type:       item.cosmetic_nail_type,
                cosmetic_nail_color:      item.cosmetic_nail_color,
                cosmetic_professional:    item.cosmetic_professional,
                cosmetic_perfume_family:  item.cosmetic_perfume_family,
                cosmetic_perfume_aroma:   item.cosmetic_perfume_aroma,

                is_fmcg:              item.is_fmcg,
                fmcg_hypoallergenic:  item.fmcg_hypoallergenic,
                fmcg_volume:          item.fmcg_volume,
                fmcg_periodic:        item.fmcg_periodic,

                is_auto:              item.is_auto,
                auto_compatibility:   item.auto_compatibility,
                auto_periodic:        item.auto_periodic,
                auto_vds:             item.auto_vds,

                is_pets:        item.is_pets,
                pets_breed:     item.pets_breed,
                pets_type:      item.pets_type,
                pets_age:       item.pets_age,
                pets_periodic:  item.pets_periodic,
                pets_size:      item.pets_size,

                is_jewelry:     item.is_jewelry,
                jewelry_gender: item.jewelry_gender,
                jewelry_color:  item.jewelry_color,
                jewelry_metal:  item.jewelry_metal,
                jewelry_gem:    item.jewelry_gem,
                ring_sizes:     item.ring_sizes,
                bracelet_sizes: item.bracelet_sizes,
                chain_sizes:    item.chain_sizes,

                is_realty:          item.is_realty,
                realty_type:        item.realty_type,
                realty_space_min:   item.realty_space_min,
                realty_space_max:   item.realty_space_max,
                realty_space_final: item.realty_space_final,

            }
          end

          if bulk.any?
            client.bulk body: bulk
          end

        end

        # Индексируем категории
        shop.item_categories.widgetable.where(external_id: active_category_ids.flatten.compact).find_in_batches(batch_size: 2000) do |categories|

          bulk = []

          categories.each do |category|
            bulk << { index: { _index: new_index_name, _type: 'category', _id: category.id } }
            bulk << {
                name:               category.name,
                uniqid:             category.external_id,
                suggest_category:   category.name.split("\s").delete_if{|x| x.length <= 2 },
                url:                category.url
            }
          end

          if bulk.any?
            client.bulk body: bulk
          end

        end

        # Index thematic collections
        shop.thematic_collections.find_in_batches(batch_size: 2000) do |collections|
          bulk = []
          collections.each do |collection|
            bulk << { index: { _index: new_index_name, _type: 'collection', _id: collection.id } }
            bulk << {
                name:               collection.name,
                suggest_collection:   collection.keywords.split("\n").delete_if{|x| x.length <= 2 }
            }
          end
          if bulk.any?
            client.bulk body: bulk
          end
        end

        # Находим индексы, от которых нужно отцепить алиас
        indices_to_delete = []
        client.cat.aliases(name: alias_name).split("\n").each do |als|
          indices_to_delete << als.split(" ")[1]
        end; nil

        # Удаляем алиас и добавляем новый
        body = {actions: []}
        indices_to_delete.each do |idx|
          body[:actions] << { remove: { index: idx, alias: alias_name } }
        end
        body[:actions] << { add: { index: new_index_name, alias: alias_name } }
        client.indices.update_aliases body: body

        # Удаляем старые индексы
        indices_to_delete.each do |idx|
          client.indices.delete index: idx
        end

        true
      end



      # Вызывать, когда при трекинге событий товар отмечается как не в наличии
      def delete_item(item_id)
        raise StandardError.new('Not implemented')
      end

      # Вызывать, когда трекается событие с новым товаром
      def add_item(item_id)
        raise StandardError.new('Not implemented')
      end




      # Delete thematic collection from index
      # @param collection ThematicCollection
      def delete_collection(collection)
        client.delete index: "shop-#{shop.id}", type: 'collection', id: collection.id
      end

      # Add thematic collection to index
      # @param collection ThematicCollection
      def add_collection(collection)
        client.index index: "shop-#{shop.id}", type: 'collection', id: collection.id, body: {
            name:               collection.name,
            suggest_collection:   collection.keywords.split("\n").delete_if{|x| x.length <= 2 }
        }
      end

      # Index structure builder
      # @return String
      def index_structure
        Jbuilder.encode do |json|

          json.settings do
            json.analysis do
              json.filter do
                json.shop_synonym_filter do
                  json.type 'synonym'
                  json.synonyms shop.query_with_synonyms
                end
              end

              json.analyzer do
                json.shop_synonyms do
                  json.tokenizer  'standard'
                  json.filter ['lowercase', 'shop_synonym_filter']
                end
              end
            end
          end

          json.mappings do
            json.product do

              json._all do
                json.enabled false
              end

              json.properties do

                json.widgetable do
                  json.type "boolean"
                end

                json.name do
                  json.type "text"
                  json.analyzer 'shop_synonyms'
                end

                json.suggest_product do
                  json.type "completion"
                  json.contexts do
                    json.array! [ %w(widgetable category) ] do |x|
                      json.set! :name, x[0]
                      json.set! :type, x[1]
                    end
                  end
                  json.analyzer 'shop_synonyms'
                end
                json.description do
                  json.type "text"
                end
                json.price do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.oldprice do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.price_margin do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.category_ids do
                  json.type "keyword"
                end
                json.location_ids do
                  json.type "keyword"
                end
                json.sales_rate do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.brand do
                  json.type "keyword"
                end
                json.picture do
                  json.enabled false
                end
                json.url do
                  json.enabled false
                end
                json.discount do
                  json.type "boolean"
                end
                json.seasonality do
                  json.type "byte"
                end
                json.leftovers do
                  json.type "keyword"
                end

                json.uniqid do
                  json.enabled false
                end
                json.type_prefix do
                  json.type "keyword"
                end
                json.vendor_code do
                  json.type "keyword"
                end
                json.model do
                  json.type "keyword"
                end

                json.barcode do
                  json.type "keyword"
                end

                json.is_fashion do
                  json.type "boolean"
                end
                json.fashion_gender do
                  json.type "keyword"
                end
                json.fashion_wear_type do
                  json.type "keyword"
                end
                json.fashion_feature do
                  json.type "keyword"
                end
                json.fashion_sizes do
                  json.type "integer"
                end

                json.is_fashion do
                  json.type "boolean"
                end
                json.fashion_gender do
                  json.type "keyword"
                end
                json.fashion_wear_type do
                  json.type "keyword"
                end
                json.fashion_feature do
                  json.type "keyword"
                end
                json.fashion_sizes do
                  json.type "integer"
                end
                json.is_child do
                  json.type "boolean"
                end
                json.child_gender do
                  json.type "keyword"
                end
                json.child_type do
                  json.type "keyword"
                end
                json.child_age_min do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.child_age_max do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.is_cosmetic do
                  json.type "boolean"
                end
                json.cosmetic_gender do
                  json.type "keyword"
                end
                json.cosmetic_hypoallergenic do
                  json.type "boolean"
                end
                json.cosmetic_skin_part do
                  json.type "keyword"
                end
                json.cosmetic_skin_type do
                  json.type "keyword"
                end
                json.cosmetic_skin_condition do
                  json.type "keyword"
                end
                json.cosmetic_hair_type do
                  json.type "keyword"
                end
                json.cosmetic_hair_condition do
                  json.type "keyword"
                end
                json.cosmetic_volume do
                  json.type "nested"
                end
                json.cosmetic_periodic do
                  json.type "boolean"
                end
                json.cosmetic_nail do
                  json.type "boolean"
                end
                json.cosmetic_nail_type do
                  json.type "keyword"
                end
                json.cosmetic_nail_color do
                  json.type "keyword"
                end
                json.cosmetic_professional do
                  json.type "boolean"
                end
                json.cosmetic_perfume_family do
                  json.type "keyword"
                end
                json.cosmetic_perfume_aroma do
                  json.type "keyword"
                end
                json.is_fmcg do
                  json.type "boolean"
                end
                json.fmcg_hypoallergenic do
                  json.type "boolean"
                end
                json.fmcg_volume do
                  json.type "nested"
                end
                json.fmcg_periodic do
                  json.type "boolean"
                end
                json.is_auto do
                  json.type "boolean"
                end
                json.auto_compatibility do
                  json.type "nested"
                end
                json.auto_periodic do
                  json.type "boolean"
                end
                json.auto_vds do
                  json.type "keyword"
                end
                json.is_pets do
                  json.type "boolean"
                end
                json.pets_breed do
                  json.type "keyword"
                end
                json.pets_type do
                  json.type "keyword"
                end
                json.pets_age do
                  json.type "keyword"
                end
                json.pets_periodic do
                  json.type "boolean"
                end
                json.pets_size do
                  json.type "keyword"
                end
                json.is_jewelry do
                  json.type "boolean"
                end
                json.jewelry_gender do
                  json.type "keyword"
                end
                json.jewelry_color do
                  json.type "keyword"
                end
                json.jewelry_metal do
                  json.type "keyword"
                end
                json.jewelry_gem do
                  json.type "keyword"
                end
                json.ring_sizes do
                  json.type 'keyword'
                end
                json.bracelet_sizes do
                  json.type 'keyword'
                end
                json.chain_sizes do
                  json.type 'keyword'
                end

                json.is_realty do
                  json.type "boolean"
                end
                json.realty_type do
                  json.type 'keyword'
                end
                json.realty_space_min do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.realty_space_max do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.realty_space_final do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end

              end
            end


            json.category do
              json._all do
                json.enabled false
              end
              json.properties do
                json.suggest_category do
                  json.type "completion"
                end
                json.name do
                  json.type "text"
                  json.analyzer 'shop_synonyms'
                end
                json.url do
                  json.enabled false
                end
                json.uniqid do
                  json.enabled false
                end
              end
            end

            json.thematic_collection do
              json.properties do
                json.suggest_collection do
                  json.type "completion"
                end
                json.name do
                  json.type "text"
                  # json.analyzer shop.search_setting.language
                  json.analyzer 'shop_synonyms'
                end
              end
            end

          end
        end
      end


    end
  end
end
