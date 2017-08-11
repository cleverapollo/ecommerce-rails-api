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
      def sync(items = nil)
        if items
          items.each { |item| sync_item(item) }
        else

          # Не забыть удалить неактивные товары
          # Делается примерно так: https://www.elastic.co/guide/en/elasticsearch/reference/5.5/docs-reindex.html
          # Создаем новый индекс, грузим в него данные, потом удаляем старый индекс, тут же его создаем и копируем в него данные из нового индекса
          temporary_index = "shop-#{shop.id}-#{rand(100)}"
          real_index = "shop-#{shop.id}"
          shop.items.recommendable.widgetable.find_each { |item| sync_item(item, temporary_index) }

          # TODO: не забыть, что при этой операции уничтожается также
          if client.indices.exists index: real_index
            client.indices.delete index: real_index
          end
          client.indices.create index: real_index
          body = Jbuilder.encode do |json|
            json.source do |json|
              json.index  temporary_index
            end
            json.dest do |json|
              json.index  real_index
            end
          end
          client.reindex body: body
          client.indices.delete index: temporary_index


          # Либо подумать про алиасы - после каждой переиндексации создавать новый индекс и перенаправлять на него алиас.
          # Альтернативно, использовать https://www.elastic.co/guide/en/elasticsearch/reference/5.5/docs-delete-by-query.html
          # для того, чтобы удалить все документы, не входящие в список ID

        end

        true
      end


      def sync_categories
      end



      private

      # Index item
      # @param [Item] item
      # @return Boolean
      def sync_item(item, index = nil)

        # Если индекс не указан, используем дефолтный
        unless index
          index = "shop-#{item.shop_id}"
        end

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
