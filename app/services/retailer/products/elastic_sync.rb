module Retailer
  module Products
    class ElasticSync

      attr_accessor :shop, :client

      # @param [Shop] shop
      def initialize(shop)
        self.shop = shop
        self.client = ElasticSearchConnector.get_connection
      end

      # @param [Item[]] items Optional list of items to sync. If not set, sync all active shop's items
      # @return Boolean
      def perform(items = nil)
        if items
          raise 'Not implemented'
          # items.each { |item| sync_item(item) }
          # Почистить удаленные продукты
          # Альтернативно, использовать https://www.elastic.co/guide/en/elasticsearch/reference/5.5/docs-delete-by-query.html
          # для того, чтобы удалить все документы, не входящие в список ID
        else

          # Не забыть удалить неактивные товары
          # Делается примерно так: https://www.elastic.co/guide/en/elasticsearch/reference/5.5/docs-reindex.html
          # Создаем новый индекс
          # Удаляем алиас, направленный на старый индекс
          # Создаем алиас на новый индекс

          new_index_name = "shop-#{shop.id}-#{DateTime.current.strftime('%Y-%m-%d-%H-%M')}"
          alias_name = "shop-#{shop.id}"

          # Массив действующих категорий
          active_category_ids = []

          # Индексируем товары
          shop.items.recommendable.widgetable.find_each do |item|
            sync_item(item, new_index_name)
            if item.category_ids
              active_category_ids += item.category_ids.flatten.compact
            end
          end

          # Индексируем категории
          shop.item_categories.where(external_id: active_category_ids.flatten.compact).find_each do |category|
            body = Jbuilder.encode do |json|
              json.name             category.name
            end
            client.index index: new_index_name, type: 'category', id: category.external_id, body: body
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

        end

        true
      end




      private

      # Index item
      # @param [Item] item
      # @return Boolean
      def sync_item(item, index)

        body = Jbuilder.encode do |json|
          json.name             item.name
          json.price            item.price.to_f
          json.category_ids     item.category_ids
          json.sales_rate       item.sales_rate.to_f
          json.brand            item.brand
        end

        client.index index: index, type: 'product', id: item.id, body: body
      end

    end
  end
end
