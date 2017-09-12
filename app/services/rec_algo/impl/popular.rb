module RecAlgo
  module Impl
    class Popular < RecAlgo::Base

      def recommendations
        check_params!

        filter_conditions = []
        filter_conditions << ['term', 'widgetable', true]
        if params.locations.any?
          # Добавляем global, чтобы находить товары, у которых не указан locations
          filter_conditions << ['terms', 'location_ids', params.locations.map { |x| x.to_s } + ['global'] ]
        end

        # Добавляем фильтры
        if rule.filters.present?
          rule.filters.each do |k,v|
            filter_conditions << [v.is_a?(Array) ? 'terms' : 'term', k, v]
          end
        end

        # Строим массив по ключам, которые не должны попадать в выборку
        exclude_conditions = []
        if rule.exclude.present?
          rule.exclude.each do |k,v|
            exclude_conditions << [v.is_a?(Array) ? 'terms' : 'term', k, v]
          end
        end

        # todo нужно генерацию параметров к запросу вынести
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
              json.must_not do
                json.array! exclude_conditions do |x|
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
        result['hits']['hits'].map { |x| x['_source']['uniqid'] }
      end

      # Проверка, валидны ли параметры для конкретного рекомендера
      def check_params!
        raise Recommendations::Error.new('Blank user') if params.user.blank?
      end

    end
  end
end
