module Retailer
  module Products
    class ElasticSync

      attr_accessor :shop, :client

      # @param [Shop] shop
      def initialize(shop)
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
        body = Jbuilder.encode do |json|
          json.mappings do
            json.product do
              json.properties do
                json.name do
                  json.type "text"
                end
                json.suggest_product do
                  json.type "completion"
                end
                json.price do
                  json.type "scaled_float"
                  json.scaling_factor 100
                end
                json.category_ids do
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
                  json.type "text"
                  json.index false
                end
              end
            end
            json.category do
              json.properties do
                json.suggest_category do
                  json.type "completion"
                end
                json.name do
                  json.type "text"
                end
                json.url do
                  json.type "text"
                  json.index false
                end
              end
            end
          end
        end
        client.indices.create index: new_index_name, body: body

        # Массив действующих категорий
        active_category_ids = []

        # Индексируем товары пачками по 2000 штук
        shop.items.recommendable.widgetable.find_in_batches(batch_size: 2000) do |items|

          bulk = []

          # Перебираем товары
          items.each do |item|

            # Пополняем список категорий для индексации
            active_category_ids += item.category_ids.flatten.compact if item.category_ids

            # Добавляем товар для индексации
            bulk << { index: { _index: new_index_name, _type: 'product', _id: item.id } }

            bulk << {
                name:             item.name,
                suggest_product:  item.name.split("\s").delete_if{|x| x.length <= 2 },
                price:            item.price.to_f,
                category_ids:     item.category_ids,
                sales_rate:       item.sales_rate.to_f,
                brand:            item.brand,
                picture:          item.resized_image_by_dimension('180x180'),
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
            bulk << { index: { _index: new_index_name, _type: 'category', _id: category.external_id } }
            bulk << {
                name:               category.name,
                suggest_category:   category.name.split("\s").delete_if{|x| x.length <= 2 },
                url:                category.url
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


    end
  end
end
