module RecAlgo
  module Impl
    class PopularInCategory < RecAlgo::Base

      def recommendations

        check_params!

        filter_conditions = []
        filter_conditions << ['term', 'widgetable', true]
        filter_conditions << ['terms', 'category_ids', params.categories] # Работает по OR
        if params.locations.any?
          # Добавляем global, чтобы находить товары, у которых не указан locations
          filter_conditions << ['terms', 'location_ids', params.locations.map { |x| x.to_s } + ['global'] ]
        end

        body = Jbuilder.encode do |json|
          json.sort do
            json.sales_rate do
              json.order 'desc'
            end
          end
          json.query do
            json.bool do
              json.filter do
                json.array! filter_conditions do |x|
                  json.set! x[0] do
                    json.set! x[1], x[2]
                  end
                end
              end
            end
          end
          json.size params.limit
        end

        result = ElasticSearchConnector.get_connection.search index: "shop-#{shop.id}", type: 'product', body: body
        return [] unless result['hits']['hits'].any?
        result['hits']['hits'].map { |x| x }
      end

      # Проверка, валидны ли параметры для конкретного рекомендера
      def check_params!
        raise Recommendations::Error.new('Blank user') if params.user.blank?
        raise Recommendations::Error.new('Empty categories list') if params.categories.blank?
      end

    end
  end
end
