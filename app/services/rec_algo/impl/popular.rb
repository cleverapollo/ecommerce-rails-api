module RecAlgo
  module Impl
    class Popular < RecAlgo::Base

      def recommendations
        check_params!
        body = Jbuilder.encode do |json|
          json.sort do
            json.sales_rate do
              json.order 'desc'
            end
          end
          json.query do
            json.bool do
              json.filter do
                json.array! [ ['term', 'widgetable', true] ] do |x|
                  json.set! x[0] do
                    json.set! x[1], x[2]
                  end
                end
              end
            end
          end
          json.size params.limit
        end

        puts body

        result = ElasticSearchConnector.get_connection.search index: "shop-#{shop.id}", type: 'product', body: body
        return [] unless result['hits']['hits'].any?
        result['hits']['hits'].map { |x| x }
      end

      # Проверка, валидны ли параметры для конкретного рекомендера
      def check_params!
        raise Recommendations::Error.new('Blank user') if params.user.blank?
      end

    end
  end
end
